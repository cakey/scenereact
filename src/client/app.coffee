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
            'EventItemFocused': this.props.isFocused
        <div className={classes}>
            <p> Name: {this.props.event.name} </p>
            <p> Desc: {this.props.event.desc} </p>
        </div>

EventScrubber = React.createClass
    render: ->
        style =
            top: "#{this.props.position*148}px" #lol
        return (
            <div className="EventScrubber">
                <div className="EventScrubberDot" style={style}></div>
            </div>
        )
EventScroller = React.createClass
    threshold: 500

    getInitialState: ->
        currentScroll: - this.threshold

    scrollHandler: (e) ->
        if this.state.currentScroll + e.deltaY > this.threshold
            if this.props.setEvent this.props.currentEvent + 1
                this.setState
                    currentScroll: 0
            else
                this.setState
                    currentScroll: this.threshold
        else if this.state.currentScroll + e.deltaY < -this.threshold
            if this.props.setEvent this.props.currentEvent - 1
                this.setState
                    currentScroll: 0
            else
                this.setState
                    currentScroll: -this.threshold
        else
            this.setState
                currentScroll: this.state.currentScroll + e.deltaY
        e.preventDefault()
    render: ->
        scrubberPosition = ((this.props.currentEvent) +
        ((this.state.currentScroll + this.threshold) / (this.threshold * 2))) / this.props.events.length

        cE = this.props.currentEvent

        <div className="EventScroller" onWheel={this.scrollHandler}>
            <div className="EventItems">
                {this.props.events.map (event, i) ->
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
        else if eventNo  >= this.props.data.length
            eventNo = this.props.data.length - 1
            changes = false
        this.setState
            currentEvent: eventNo
        return changes

    render: ->
        <div className="EventPanel">
            <MapWidget />
            <EventScroller
                events={this.props.data}
                currentEvent={this.state.currentEvent}
                setEvent={this.setEvent} />
        </div>

React.render(
    <EventPanel data={data} />
    document.getElementById('content')
)
