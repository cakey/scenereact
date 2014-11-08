_ = require 'lodash'
React = require "react"

Box = React.createClass
    displayName: 'Box',
    render: ->
        React.createElement('div', {className: "Box"},
        "Hello, world! I am a Box.")

React.render(
    React.createElement(Box, null),
    document.getElementById('content')
)
