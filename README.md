Fully working, but very early version, this is the accompanying app to a yet-to-be-realease model. The plan is a free model and a subscription app for businesses >10 employees.
Right now it's free, any critic or request: tell us.

Full native macOS SwiftUI app, minimal code, no external dependency, no internet required, no data collected, user-experience oriented as-in you can "cmd+o" to open an image/video.
Many times, you have an image and you don't see anything because it's very bright, but a little touch on the exposure slider astonishly reveals edges, shapes or even details.
Sometimes, it just makes it worse and all that is left are clusters of dark pixels.
Super-Resolution has a tendency to blur out little details.
Generative models can generate new features.

"Is this what I think it is?"
"What was that?"
"What's in his hands?"
"What is he putting in his pocket?"
"Is that a woman in the reflection of the spoon?"
"What time is displayed on his watch?"
"
The objective of the app is to remove all doubts to the previous question, without creating new images.
Image-enhancement, super-resolution and other "IA" models aren't the main functions of the app, however all Core ML capabilities are supported: we believe image-enhancement as an investigative tool has its arguments, for exemple fast-fourrier enhancements are valid algorythms for fingerprint matching, and if we take into account that same-DNA twins possess different fingerprints, it is all quite remarkable.
The app does not create new images, it creates images that can theorically be restored into the original image: all results are reproducible, and should give the same exact results.


Main functions:
Extensive color and light processing sliders for still or video images using native Core Image.
Real-time video processing
All filters are supported, however only the one I used are presented, it's just two or three lines of code to add, let me know whichever other is required.
CoreML image2image supports real time.
CoreML object detection 
---to complete---tocomplete----

