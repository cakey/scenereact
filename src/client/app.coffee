# TODO:
# 1. propagating the event methods seems a little ridiculous...
#   should set up an event system
# 2. Pull out buttons to sub react components??
# 3. Re add smooth scrolling (state var?)
# 4. Refactor methods in EventPanel

_ = require 'lodash'
React = require "react/addons"

GMap = require "./gmap.coffee"

Mousetrap = require "br-mousetrap"

_m = require("mediator-js").Mediator

mediator = new _m()

data = require("./defaultData.coffee").life

EventItem = React.createClass
    onClick: (e) ->
        e.stopPropagation()
        mediator.publish "setEvent", @props.eventNo

    deleteEvent: (e) ->
        e.stopPropagation()
        mediator.publish "deleteEvent", @props.eventNo

    upEvent: (e) ->
        e.stopPropagation()
        mediator.publish "upEvent", @props.eventNo

    downEvent: (e) ->
        e.stopPropagation()
        mediator.publish "downEvent", @props.eventNo

    changeName: (e, v) ->
        mediator.publish "updateEvent", @props.eventNo, name: e.target.value

    changeDesc: (e, v) ->
        mediator.publish "updateEvent", @props.eventNo, description: e.target.value

    render: ->
        classes = React.addons.classSet
            'EventItem': true
            'EventItemFocused': @props.isFocused

        values =
            if @props.editable and @props.isFocused
                <div>
                    <input className="editable bold" value={@props.event.name} onChange={@changeName} />
                    <textarea className="editable" value={@props.event.description} onChange={@changeDesc}  />
                    {if @props.eventNo > 0
                        <img src="assets/glyphicons-214-up-arrow.png" className="upItemButton" onClick={@upEvent}/>
                    }
                    <img src="assets/glyphicons-208-remove-2.png" className="deleteItemButton" onClick={@deleteEvent}/>
                    {if @props.eventNo < (@props.countEvents - 1)
                        <img src="assets/glyphicons-213-down-arrow.png" className="downItemButton" onClick={@downEvent}/>
                    }
                </div>
            else
                <div>
                    <p><b>{@props.event.name}</b></p>
                    <p>{@props.event.description}</p>
                </div>

        <div className={classes} onClick={@onClick}>
            {values}
        </div>

EventScroller = React.createClass

    addEvent: ->
        mediator.publish "addEvent"

    render: ->
        cE = @props.currentEvent

        <div className="EventScroller" onWheel={@scrollHandler}>
            <div className="EventItems">
                {@props.events.map (event, i) =>
                    <EventItem
                        event={event} key={i} eventNo={i}
                        countEvents={@props.events.length}
                        isFocused={cE==i}
                        editable={@props.editable}
                    />
                }
                {
                    if @props.editable
                        <div id="addItemButton" onClick={@addEvent}>
                            <span className="helper"></span>
                            <img id="addItemButtonImage" src="assets/glyphicons-433-plus.png" />
                        </div>
                }
            </div>
        </div>

MapWidget = React.createClass
    render: ->
        <div className="MapWidget">
            <GMap
                view={@props.event}
            />
        </div>

TimeLineWidget = React.createClass
    render: ->
        <div className="TimeLineWidget">
            <div className="TimeLineLine" ></div>
                {@props.events.map (event, i) =>
                    style =
                        top: "#{((i / (@props.events.length-1)))*100}%"
                        background: if @props.currentEvent == i then "#ccc" else "#eee"
                    <div
                        className="TimeLinePoint"
                        key={i}
                        style={style}
                    />
                }
        </div>

EventPanel = React.createClass
    getInitialState: ->
        prevState = localStorage.getItem "sceneEventState"
        if prevState?
            console.log "Found Saved Data!"
            console.log prevState
            currentEvent: 0
            editable: false
            data: JSON.parse prevState
        else
            currentEvent: 0
            editable: false
            data: _.cloneDeep @props.defaultData

    componentDidMount: ->
        mediator.subscribe "setEvent", @setEvent
        mediator.subscribe "upEvent", @upEvent
        mediator.subscribe "downEvent", @downEvent
        mediator.subscribe "deleteEvent", @deleteEvent
        mediator.subscribe "addEvent", @addEvent
        mediator.subscribe "updateEvent", @updateEvent

        Mousetrap.bind ['down', 'right'], =>
            mediator.publish "setEvent", @state.currentEvent + 1

        Mousetrap.bind ['up', 'left'], =>
            mediator.publish "setEvent", @state.currentEvent - 1

    componentWillUnmount: ->
        Mousetrap.unbind ['down', 'right']
        Mousetrap.unbind ['up', 'left']

    componentWillUpdate: ->
        jsonState = JSON.stringify @state.data
        console.log jsonState
        localStorage.setItem "sceneEventState", jsonState

    boundEvent: (eventNo, data) ->
        if eventNo < 0
            0
        else if eventNo >= data.length
            data.length - 1
        else
            eventNo

    setEvent: (eventNo) ->
        @setState
            currentEvent: @boundEvent eventNo, @state.data

    deleteEvent: (eventNo) ->
        newData = _.cloneDeep @state.data
        newData.splice eventNo, 1
        @setState
            data: newData
            currentEvent: @boundEvent eventNo, newData

    updateEvent: (eventNo, obj) ->
        newData = _.cloneDeep @state.data
        for k, v of obj
            newData[eventNo][k] = v
        @setState
            data: newData

    upEvent: (eventNo, obj) ->
        newData = _.cloneDeep @state.data
        newData.splice (eventNo - 1), 2, newData[eventNo], newData[eventNo-1]
        @setState
            data: newData
            currentEvent: @state.currentEvent - 1

    downEvent: (eventNo, obj) ->
        newData = _.cloneDeep @state.data
        newData.splice eventNo, 2, newData[eventNo+1], newData[eventNo]
        @setState
            data: newData
            currentEvent: @state.currentEvent + 1

    addEvent: ->
        newEvent = getPoint() # TODO: urghh
        newEvent.name = "Copy of #{@state.data[@state.currentEvent].name}"
        newEvent.description = "Describe me!"
        newData = _.cloneDeep @state.data
        newData.push newEvent
        @setState
            data: newData
            currentEvent: newData.length - 1

    toggleEditable: ->
        @setState
            editable: not @state.editable

    render: ->
        editText = if @state.editable then "done" else "edit"
        image = "assets/glyphicons-#{if @state.editable then "207-ok-2" else "31-pencil"}.png"
        <div className="EventPanel">
            <TimeLineWidget
                events={@state.data}
                currentEvent={@state.currentEvent}
            />
            <MapWidget event={@state.data[@state.currentEvent]} />
            <EventScroller
                events={@state.data}
                currentEvent={@state.currentEvent}
                editable={@state.editable}
            />
            <div id="toggleEditButton#{@state.editable}" onClick={@toggleEditable}>
                <img id="toggleEditImage" src={image} />
            </div>
        </div>

React.initializeTouchEvents true
React.render(
    <EventPanel defaultData={data} />
    document.getElementById 'content'
)
