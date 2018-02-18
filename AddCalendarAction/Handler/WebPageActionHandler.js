var WebPageActionHandler = function() {};

WebPageActionHandler.prototype = {
run: function(arguments) {
    // Pass the baseURI of the webpage to the extension.
    console.log("hoge");
    arguments.completionFunction({"baseURI": document.baseURI, "content": document.documentElement.innerHTML});
}
};

// The JavaScript file must contain a global object named "ExtensionPreprocessingJS".
var ExtensionPreprocessingJS = new WebPageActionHandler;
