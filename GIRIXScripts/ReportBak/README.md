# Overview

This Scriptlet contains extendable HTML templates. Code for single diagrams are located in the diagrams folder. The main.r contains the code to call all the diagram functions and has annotations for knitr. The index.Rhtml is a html template where knitr injects the diagrams. So in the end you get the following flow:

~~~
R Files with diagrams -> main.r -> main.Rhtml -> main.html
~~~

This is done with a simple `make` which also triggers a reload in the browser.

