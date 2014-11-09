_ = require 'lodash'
React = require "react/addons"

data = [
    {
        name: "Ben"
        desc: "Test1"
        id: 1
    },
    {
        name: "John"
        desc: "Test2"
        id: 2
    },
]

EventItem = React.createClass
    render: ->
        classes = React.addons.classSet
            'EventItem': true
            'EventItemFocused': @props.isFocused
        <div className={classes}>
            <p> Name: {@props.event.name} </p>
            <p> Desc: {@props.event.desc} </p>
        </div>

EventScrubber = React.createClass
    render: ->
        style =
            top: "#{@props.position*148}px" #lol
        return (
            <div className="EventScrubber">
                <div className="EventScrubberDot" style={style}></div>
            </div>
        )
EventScroller = React.createClass
    threshold: 500

    getInitialState: ->
        currentScroll: - @threshold

    scrollHandler: (e) ->
        if @state.currentScroll + e.deltaY > @threshold
            if @props.setEvent @props.currentEvent + 1
                @setState
                    currentScroll: 0
            else
                @setState
                    currentScroll: @threshold
        else if @state.currentScroll + e.deltaY < -@threshold
            if @props.setEvent @props.currentEvent - 1
                @setState
                    currentScroll: 0
            else
                @setState
                    currentScroll: -@threshold
        else
            @setState
                currentScroll: @state.currentScroll + e.deltaY
        e.preventDefault()
    render: ->
        scrubberPosition = ((@props.currentEvent) +
        ((@state.currentScroll + @threshold) / (@threshold * 2))) / @props.events.length

        cE = @props.currentEvent

        <div className="EventScroller" onWheel={@scrollHandler}>
            <div className="EventItems">
                {@props.events.map (event, i) ->
                    <EventItem event={event} key={i} isFocused={cE==i} />
                }
            </div>
            <EventScrubber position={scrubberPosition} />
        </div>

MapWidget = React.createClass
    render: ->
        <div className="MapWidget">
            I am a map MapWidget
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
            <MapWidget />
            <EventScroller
                events={@props.data}
                currentEvent={@state.currentEvent}
                setEvent={@setEvent} />
        </div>

React.render(
    <EventPanel data={data} />
    document.getElementById('content')
)
