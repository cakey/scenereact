# TODO:
# * Pull out buttons to sub react components??
# * Re add smooth scrolling (state var?)
# * Refactor methods in EventPanel
# * Why is getPoint global zZz

_ = require 'lodash'
React = require "react/addons"
Mousetrap = require "br-mousetrap"
mediator = require("mediator-js").Mediator()
moment = require "moment"
uuid = require "uuid"

GMap = require "./gmap.coffee"
DefaultData = require "./defaultData.coffee"

Firebase = require "firebase"
firebase = new Firebase "https://scene.firebaseio.com"




EventItem = React.createClass
    onClick: (e) ->
        e.stopPropagation()
        if not (@props.isFocused and @props.editable)
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
            'focused': @props.isFocused

        values =
            if @props.editable and @props.isFocused
                <div>
                    <textarea className="editable bold" value={@props.event.name} onChange={@changeName} />
                    <textarea className="editable" value={@props.event.description} onChange={@changeDesc}  />
                    {if @props.eventNo > 0
                        <img src="/assets/glyphicons-214-up-arrow.png" className="upItemButton" onClick={@upEvent}/>
                    }
                    <img src="/assets/glyphicons-208-remove-2.png" className="deleteItemButton" onClick={@deleteEvent}/>
                    {if @props.eventNo < (@props.countEvents - 1)
                        <img src="/assets/glyphicons-213-down-arrow.png" className="downItemButton" onClick={@downEvent}/>
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
                            <img id="addItemButtonImage" src="/assets/glyphicons-433-plus.png" />
                        </div>
                }
            </div>
        </div>

pointsEqual = (a, b) ->
    (a.zoom is b.zoom and
    Math.abs(a.latitude - b.latitude) < 0.00000001 and
    Math.abs(a.longitude - b.longitude) < 0.00000001)


MapWidget = React.createClass

    getInitialState: ->
        mapLocation: @props.event
        fromMap: false

    componentWillReceiveProps: (nextProps) ->
        # Don't reset the map to prop point if switching to editable mode.
        if @props.editable is nextProps.editable
            @setState
                mapLocation: nextProps.event
                fromMap: false

    onMapMove: (newMapLocation) ->
        if not pointsEqual newMapLocation, @state.mapLocation
            @setState
                mapLocation: newMapLocation
                fromMap: true

    resetLocation: ->
        @setState
            mapLocation: @props.event
            fromMap: false

    setLocation: ->
        mediator.publish "updateEvent", null, @state.mapLocation

    render: ->
        markers =
            if @props.editable
                m = _.cloneDeep @state.mapLocation
                m.draggable = true
                [m]
            else
                [@props.event]
        <div className="MapWidget">
            <GMap
                view={@state.mapLocation}
                markers={markers}
                mapMove={@onMapMove}
                fromMap={@state.fromMap}
                editable={@props.editable}
            />
            {
                if @props.editable and not pointsEqual @props.event, @state.mapLocation
                    <div>
                        <div className="resetLocationButton"
                            onClick={@resetLocation}>Reset
                        </div>
                        <div className="setLocationButton"
                            onClick={@setLocation}>Set Location
                        </div>
                    </div>

            }
        </div>

TimeLinePoint = React.createClass
    onClick: ->
        if not (@props.active and @props.editable)
            mediator.publish "setEvent", @props.eventNo

    render: ->
        classes = React.addons.classSet
            "TimeLinePoint": true
            'active': @props.active
        style =
            top: "#{@props.top}%"
        <div
            className={classes}
            style={style}
            onClick={@onClick}
        >
            { @props.eventNo + 1 }
        </div>

TimeLineWidget = React.createClass
    render: ->
        <div className="TimeLineWidget">
            <div className="TimeLineLine" ></div>
                {@props.events.map (event, i) =>
                    top =
                        if @props.events.length is 1
                            50
                        else
                            (i / (@props.events.length - 1)) * 100
                    <TimeLinePoint
                        eventNo={i}
                        active={@props.currentEvent == i}
                        top={top}
                        key={i}
                        editable={@props.editable}
                    />
                }
        </div>

EventPanel = React.createClass
    getInitialState: ->
        id = window.location.pathname
        if id[0] is '/'
            id = id[1..]
        if id isnt ''
            firebase.child("stories").child(id).on "value", (story) =>
                newStory = story.val()
                if newStory? and not _.isEqual @state.data, newStory
                    @setState
                        data: newStory
                        last: newStory
            currentEvent: 0
            editable: false
            data: _.cloneDeep @props.defaultData
        else
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

    componentWillUpdate: (nextProps, nextState) ->
        jsonState = JSON.stringify @state.data
        console.log jsonState

        id = window.location.pathname
        if id[0] is '/'
            id = id[1..]
        if id isnt ''
            if not _.isEqual nextState.last, nextState.data
                firebase.child("stories").child(id).set nextState.data
        else
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
        if not eventNo?
            eventNo = @state.currentEvent

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
        newEvent.name = "Copy of #{@state.data[@state.currentEvent]?.name}"
        newEvent.description = "Describe me!"
        newData = _.cloneDeep @state.data
        newData.push newEvent
        @setState
            data: newData
            currentEvent: newData.length - 1

    # share: ->
    #     console.log @state.data
    #     u = uuid.v4()
    #     stories = firebase.child "stories"
    #     currentStory = stories.child u
    #     currentStory.set @state.data

    toggleEditable: ->
        @setState
            editable: not @state.editable

    render: ->
        editText = if @state.editable then "done" else "edit"
        image = "/assets/glyphicons-#{if @state.editable then "207-ok-2" else "31-pencil"}.png"
        <div className="EventPanel">
            <TimeLineWidget
                events={@state.data}
                currentEvent={@state.currentEvent}
                editable={@state.editable}
            />
            <MapWidget
                event={@state.data[@state.currentEvent]}
                editable={@state.editable}
                mapMove={@onMapMove}
            />
            <EventScroller
                events={@state.data}
                currentEvent={@state.currentEvent}
                editable={@state.editable}
            />
            <div
                id="toggleEditButton"
                className={if @state.editable then "editable" else ""}
                onClick={@toggleEditable}
            >
                <img id="toggleEditImage" src={image} />
            </div>
        </div>
        # <div
        #     id="shareButton"
        #     onClick={@share}
        # >
        #     <img id="shareButtonImage" src="/assets/glyphicons-500-family.png" />
        # </div>

React.initializeTouchEvents true
React.render(
    <EventPanel defaultData={DefaultData.default} />
    document.getElementById 'content'
)
