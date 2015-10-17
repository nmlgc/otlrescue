Canon CaptureOnTouch temp file rescuer
--------------------------------------
#### Description
When using the Canon CaptureOnTouch (Lite) scanning software, newly scanned
pages are first saved using a custom temporary format to `%TEMP%\otl*.tmp`
directory. All pages scanned in a session stay there until you formally save
them in their intended format through the GUI.

They also remain there if CaptureOnTouch or Windows crashes before they are
saved. Unfortunately, CaptureOnTouch doesn't offer any rescuing option in this
case, even though it would clearly be possible.

This tool is meant to provide this missing feature by simply converting those
temp files to BMPs so that you can still use them with your image
viewer/editor/converter of choice and don't have to rescan the pages.

##### Why Assembly?
Originally, I wanted to use the occasion of having to write this tool to check
out [Rust] instead. However, I couldn't even get as far as *reading the Canon
header structure*, since the obviously trivial act of **simply reading what C
calls a struct from a file** seems to involve [deprecated] or [unstable]
functions hidden deep in the standard library, which, of course, I could not
get to compile on my local Rust installation or even on the [Rust Playground].

That was actually my third look at that language, and I didn't get very far in
the other two attempts either, due to similar detail issues and then recent
deprecations in the language. No, that's not how you replace C. [Jai] is.

So I jokingly thought that, given the eventual size of the program, even
Assembly would seem to be a better tool for the job than Rust, at the current
time and with my current skills.

Another reason was that I'm doing coding livestreams at an undisclosed location
from time to time, and my regular viewers always enjoy me whipping out the
assembly hammer. ☺

#### Building
You'll need POASM and POLINK, part of [Pelles C]. This assembler and linker
were chosen because we need to get the Win32 API libraries from *somewhere*,
and Pelles C seems to be the most bloat-free and comfortable package on Windows
nowadays. (Also, the MASM32 installer is just… weird.)

From the Pelles C command prompt, simply run `build`. That's it.

----

[Rust]: http://rust-lang.org
[Rust Playground]: https://play.rust-lang.org/
[Jai]: https://www.youtube.com/watch?v=UTqZNujQOlA
[deprecated]: http://smallcultfollowing.com/rust-int-variations/imem-umem/std/slice/raw/fn.buf_as_slice.html
[unstable]: http://smallcultfollowing.com/rust-int-variations/imem-umem/std/slice/fn.from_raw_buf.html
[Pelles C]: http://www.smorgasbordet.com/pellesc/
