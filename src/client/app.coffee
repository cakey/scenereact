_ = require 'lodash'
React = require "react/addons"

GMap = require "./gmap.coffee"

Mousetrap = require "br-mousetrap"

makePoints = (startPoint, endPoint) ->
    # TODO: Will zoom out too far for close points.
    # TODO: Weight should be based on before and after zoom, not just after.
    # TODO: Don't smove in highest level zoom.
    maxZoom = 21
    minZoom = 3

    curveFactor = 2.5 # Higher = zoom out quicker before panning

    zoomOut = startPoint.zoom - minZoom
    zoomIn = endPoint.zoom - minZoom

    totalWeightedDistance = 0
    for zoom in [startPoint.zoom-1 .. minZoom]
        console.log zoom
        totalWeightedDistance += Math.pow curveFactor, (maxZoom - zoom)

    for zoom in [endPoint.zoom .. minZoom]
        console.log zoom
        totalWeightedDistance += Math.pow curveFactor, (maxZoom - zoom)

    points = [startPoint]
    currentPoint = startPoint

    for zoom in [startPoint.zoom-1 .. minZoom]
        weight = Math.pow(curveFactor, (maxZoom - zoom)) / totalWeightedDistance
        currentPoint =
            weight: weight
            zoom:zoom
            latitude: currentPoint.latitude + (endPoint.latitude - startPoint.latitude) * weight
            longitude: currentPoint.longitude + (endPoint.longitude - startPoint.longitude) * weight
        points.push currentPoint

    for zoom in [minZoom .. endPoint.zoom]
        weight = Math.pow(curveFactor, (maxZoom - zoom)) / totalWeightedDistance
        currentPoint =
            weight: weight
            zoom: zoom
            latitude: currentPoint.latitude + (endPoint.latitude - startPoint.latitude) * weight
            longitude: currentPoint.longitude + (endPoint.longitude - startPoint.longitude) * weight
        points.push currentPoint

    points

data = makePoints
    latitude: 52.234259
    longitude: 0.153287
    zoom: 15
,
    latitude: 37.744975
    longitude: -122.419062
    zoom: 18

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
                latitude={@props.event.latitude}
                longitude={@props.event.longitude}
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
