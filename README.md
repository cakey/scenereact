## setup
    # 1. Install node
    npm i -g gulp nodemon coffee-script
    npm install

You will also need a keys.coffee file in src/config.
Example:

	keys =
	    gmaps: "mygmapsapikey"
	
	module.exports = keys


## to dev (watches for file changes, and runs dev server)
	gulp
    gulp tdd # separate tab for karma tests
    nodemon -w src/server -w src/lib src/server/main.coffee # run server
    
## stack
 * http://sass-lang.com/guide
 * http://coffeescript.org/
 * http://jade-lang.com/
 * http://gulpjs.com/
