_ = require 'lodash'
React = require "react/addons"

GMap = require "./gmap.coffee"

Mousetrap = require "br-mousetrap"

data = [
    latlng: [51.408411,-0.15022]
    zoom: 9
    name: "London"
    description: "Born and raised."
    datetime: "1990-2009"
,
    latlng: [52.204,0.118902]
    zoom: 14
    name: "Cambridge"
    description: "The University Years"
    datetime: "2009-2013"
,
    latlng: [52.234259,0.153287]
    zoom: 15
    name: "Detour"
    description: "Cheeky Gap Year..."
    datetime: "2012"
,
    latlng: [37.735863,-122.414019]
    zoom: 11
    name: "SF"
    description: "Venturing into the wild!"
    datetime: "Sep 2013"
,
    latlng: [37.744975,-122.419062]
    zoom: 17
    name: "Bernal Mission"
    description: "I find my home!"
    datetime: "Nov 2013"
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
            top: "#{@props.position*78*5}px" #lol
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
            <EventScrubber position={scrubberPosition} />
        </div>

MapWidget = React.createClass
    render: ->
        <div className="MapWidget">
            <GMap
                latitude={@props.event.latlng[0]}
                longitude={@props.event.latlng[1]}
                zoom={@props.event.zoom}
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
    document.getElementById('content')
)
