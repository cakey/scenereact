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
    zoom: 11
    name: "Lake Tahoe"
    description: "skii"
]

EventItem = React.createClass
    onClick: ->
        @props.setEvent @props.eventNo

    render: ->
        classes = React.addons.classSet
            'EventItem': true
            'EventItemFocused': @props.isFocused
        <div className={classes} onClick={@onClick}>
            <p> Name: {@props.event.name} </p>
            <p> Desc: {@props.event.description} </p>
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
                    <EventItem event={event} key={i} eventNo={i} isFocused={cE==i} setEvent={@setEvent} />
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

    setEvent: (eventNo) ->
        changes = true
        if eventNo  < 0
            eventNo = 0
            changes = false
        else if eventNo  >= @props.data.length
            eventNo = @props.data.length - 1
            changes = false
        @setState
            currentEvent: eventNo
        return changes

    render: ->
        <div className="EventPanel">
            <MapWidget event={@props.data[@state.currentEvent]} />
            <EventScroller
                events={@props.data}
                currentEvent={@state.currentEvent}
                setEvent={@setEvent} />
        </div>

React.render(
    <EventPanel data={data} />
    document.getElementById 'content'
)
