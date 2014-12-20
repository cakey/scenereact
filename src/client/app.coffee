_ = require 'lodash'
React = require "react/addons"

GMap = require "./gmap.coffee"

Mousetrap = require "br-mousetrap"

data = [
    latitude: 52.234259
    longitude: 0.153287
    zoom: 15
    name: "Cambridge"
    description: "University"
,
    zoom: 9,
    latitude: 37.559267971339345
    longitude: -122.28022291183471
    name: "SILICON VALLEY"
    description: "ok?"
,
    latitude: 37.793
    longitude: -122.395
    zoom: 16
    name: "SFDC"
    description: "Work"
,
    latitude: 37.744975
    longitude: -122.419062
    zoom: 17
    name: "San Francisco"
    description: "Home"
,
    latitude: 39.083742
    longitude: -119.973214
    zoom: 10
    name: "Lake Tahoe"
    description: "skii"
,
    zoom: 14
    latitude: 38.93952062454573
    longitude: -119.90914139105224
    name: "HEAVEN"
    description: "LY"
]

EventItem = React.createClass
    onClick: ->
        @props.setEvent @props.eventNo

    deleteEvent: ->
        @props.deleteEvent @props.eventNo

    changeName: (e, v) ->
        @props.updateEvent @props.eventNo, name: e.target.value

    changeDesc: (e, v) ->
        @props.updateEvent @props.eventNo, description: e.target.value

    render: ->
        classes = React.addons.classSet
            'EventItem': true
            'EventItemFocused': @props.isFocused

        values =
            if @props.editable and @props.isFocused
                <div>
                    <input className="editable bold" value={@props.event.name} onChange={@changeName} />
                    <input className="editable" value={@props.event.description} onChange={@changeDesc}  />
                </div>
            else
                <div>
                    <p><b>{@props.event.name}</b></p>
                    <p>{@props.event.description}</p>
                </div>

        <div className={classes} onClick={@onClick}>
            {values}
            {if @props.editable
                <img src="assets/glyphicons-208-remove-2.png" className="deleteItem" onClick={@deleteEvent}/>
            }
        </div>

EventScrubber = React.createClass
    render: ->
        style =
            top: "#{@props.position*78*@props.eventCount}px" #lol
        return (
            <div className="EventScrubber">
                <div className="EventScrubberDot" style={style}></div>
            </div>
        )
EventScroller = React.createClass
    threshold: 500

    componentDidMount: ->
        Mousetrap.bind ['down', 'right'], =>
            @props.setEvent @props.currentEvent + 1
            @setState
                currentScroll: 0
        Mousetrap.bind ['up', 'left'], =>
            @props.setEvent @props.currentEvent - 1
            @setState
                currentScroll: 0

    componentWillUnmount: ->
        Mousetrap.unbind ['down', 'right']
        Mousetrap.unbind ['up', 'left']

    getInitialState: ->
        currentScroll: - @threshold

    setEvent: (e) ->
        @props.setEvent e
        @setState
            currentScroll: 0
    deleteEvent: (e) ->
        @props.deleteEvent e

    updateEvent: (eId, v) ->
        @props.updateEvent eId, v

    scrollHandler: (e) ->
        wantedScroll = @state.currentScroll + e.deltaY

        newScroll =
            if wantedScroll > @threshold
                if @props.setEvent @props.currentEvent + 1
                    -@threshold
                else
                    @threshold
            else if wantedScroll < -@threshold
                if @props.setEvent @props.currentEvent - 1
                    @threshold
                else
                    -@threshold
            else
                @state.currentScroll + e.deltaY

        @setState
            currentScroll: newScroll

        e.preventDefault()

    render: ->
        scrubberPosition = ((@props.currentEvent) +
        ((@state.currentScroll + @threshold) / (@threshold * 2))) / @props.events.length

        cE = @props.currentEvent

        <div className="EventScroller" onWheel={@scrollHandler}>
            <div className="EventItems">
                {@props.events.map (event, i) =>
                    <EventItem
                        event={event} key={i} eventNo={i}
                        isFocused={cE==i}
                        setEvent={@setEvent}
                        deleteEvent={@deleteEvent}
                        updateEvent={@updateEvent}
                        editable={@props.editable}
                    />
                }
            </div>
            <EventScrubber eventCount={@props.events.length} position={scrubberPosition} />
        </div>

MapWidget = React.createClass
    render: ->
        <div className="MapWidget">
            <GMap
                view={@props.event}
            />
        </div>

EventPanel = React.createClass
    getInitialState: ->
        currentEvent: 0
        editable: false
        data: _.cloneDeep @props.data

    setEvent: (eventNo) ->
        changes = true
        if eventNo  < 0
            eventNo = 0
            changes = false
        else if eventNo  >= @state.data.length
            eventNo = @state.data.length - 1
            changes = false
        @setState
            currentEvent: eventNo
        return changes

    deleteEvent: (eventNo) ->
        newData = _.cloneDeep @state.data
        newData.splice eventNo, 1
        @setState
            data: newData

    updateEvent: (eventNo, obj) ->
        newData = _.cloneDeep @state.data
        for k, v of obj
            newData[eventNo][k] = v
        @setState
            data: newData

    toggleEditable: ->
        @setState
            editable: not @state.editable

    render: ->
        editText = if @state.editable then "done" else "edit"
        image = "assets/glyphicons-#{if @state.editable then "207-ok-2" else "31-pencil"}.png"
        <div className="EventPanel">
            <MapWidget event={@state.data[@state.currentEvent]} />
            <EventScroller
                events={@state.data}
                currentEvent={@state.currentEvent}
                setEvent={@setEvent}
                deleteEvent={@deleteEvent}
                updateEvent={@updateEvent}
                editable={@state.editable}
            />
            <div id="toggleEditButton#{@state.editable}" onClick={@toggleEditable}>
                <span className="helper"></span>
                <img id="toggleEditImage" src={image} />
            </div>
        </div>

React.render(
    <EventPanel data={data} />
    document.getElementById 'content'
)
