_ = require 'lodash'
React = require "react"

Box = React.createClass
    displayName: 'Box',
    render: ->
      <div className="Box">
        Hello, world! I am a Boxxx.
      </div>

React.render(
    React.createElement(Box, null),
    document.getElementById('content')
)
