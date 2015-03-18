# Overview

This repository contains the development environment for my R development. Code for single diagrams are located in the diagrams folder. The main.r contains the code to call all the diagram functions and has annotations for knitr. The index.Rhtml is a html template where knitr injects the diagrams. So in the end you get the following flow:

~~~
R Files with diagrams -> main.r -> main.Rhtml -> main.html
~~~

This is done with a simple `make` which also triggers a reload in the browser.

# Setup

### Using LiveReload
- `npm install --save-dev make-livereload`
- Install LiveReload Chrome Plugin
- Start livereload: `make livereload`
- Stop livereload: `make livereload-stop`

### Build the html file
- `make`

### Open html file
- `make open`
