_ = require 'lodash'
React = require "react"

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

IBox = React.createClass
    handleClick: (e) ->
        alert "yo"
    render: ->
        commentNodes = this.props.data.map (person) ->
            <div key={person.id}>
                Hello, world! name is {person.name}
                Hello, world! desc is {person.desc}
            </div>

        return <div className="iBox">
            {commentNodes}
            <button onClick={this.handleClick}>Click Me</button>
        </div>

Box = React.createClass
    render: ->
        <div className="Box">
            <IBox data={this.props.data} />
            Hello, world! I am a Boxsxsx2.
        </div>

React.render(
    <Box data={data} />
    document.getElementById('content')
)
