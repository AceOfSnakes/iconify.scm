;Iconify.scm
;===========================
;Author...Giuseppe Bilotta
;Modified for Gimp 2.4.6+ by Ouch67
;http://www.gimptalk.com/forum/broken-scripts-t33501.html
;Resubmission to Gimp Plugin Registry & GimpTalk by Gargy
;Modified for Gimp 2.8 by Roland Clobus
;Modified for Gimp 2.99.8+ by GlitchyPie
;	2023-08-18 Additional updates to fix breaking changes since aprox Gimp 2.99.16
;------------
;Description...: Iconify plug-in converts a single layer of a single image into a multi-layered image ready to be saved as a Windows icon.
;The new image will contain all standard sizes (16x16, 32x32, 48x48) at all standard bit depths (16 colors, 256 colors, 32-bit RGBA), with transparency support.
;The new image will also contain a big version (256x256 32-bit RGBA)
;===========================
;
; Note: This script was modified accordingly with the changes stated here: http://www.aqua-soft.org/forum/topic/40999-iconify-plug-in-for-the-gimp/
; ( https://web.archive.org/web/20230818185151/https://www.aqua-soft.org/forum/topic/40999-iconify-plug-in-for-the-gimp/ )
; 
; 
; Changes by GlitchyPie only involved replacing old functions and function names to 2.99.8+ equivalents
;
; 2023-08-18: GlitchyPie :
;           : Changed deprecated -get-filename and -set-filename to -get-file and -set-file
;           : Added .xcf to new-name as recent implementation now enforces previously poorly document requirement
;             See: https://gitlab.gnome.org/GNOME/gimp/-/issues/9657
;           : Furthere updates warrented as there are further deprecated transfrom functions being used
;
; 2025-03-18: Ace Of Snakes :
;           : try to run it under GIMP 3.0
;
; It converts an image into a Windows/Macintosh icon
(define (script-fu-iconify img drawable)
; Create a new image. It's also easy to add
; 128x128 Macintosh icons, or other sizes
(let* (
       (new-img (car (gimp-image-new 256 256 0)))
       (new-name 0)
       (work-layer 0)
       (big-layer 0)
       (layer-x 0)
       (layer-y 0)
       (max-dim 0)
       (temp-layer 0)

       (temp-img 0)
       (layers 0)
       (layernum 0)
       (layers-array 0)
       (layer 0)
       (eigth-bit 0)
       (four-bit 0)
       )
; Set the name of the new image by replacing the extension with .ico
; FIXME this doesn't work as intended for files without extension
; or files with multiple extensions.
(set! new-name
(append
(butlast
(strbreakup (car (gimp-image-get-file img)) ".")
)
'(".ico.xcf")
)
)
(set! new-name (eval (cons string-append new-name)))
(gimp-image-set-file new-img new-name)

; Create a new layer
(set! work-layer (car (gimp-layer-new-from-drawable drawable new-img)))

; Give it a name
(gimp-item-set-name work-layer "Work layer")

; Add the new layer to the new image
(gimp-image-insert-layer new-img work-layer 0 -1)

; Autocrop the layer
;;;;;;;;(plug-in-autocrop-layer 1 new-img work-layer)

; Now, resize the layer so that it is square,
; by making the shorter dimension the same as
; the longer one. The layer content is centered.
(set! layer-x (car (gimp-drawable-get-width work-layer)))
(set! layer-y (car (gimp-drawable-get-height work-layer)))

(set! max-dim (max layer-x layer-y))
(gimp-layer-resize work-layer max-dim max-dim (/ (- max-dim layer-x) 2) (/ (- max-dim layer-y) 2))

; Move the layer to the origin of the image
(gimp-layer-set-offsets work-layer 0 0)

; Now, we create as many layers as needed, resizing to
; 16x16, 32x32, 48x48, 128x128, 256x256

(define (resize-to-dim dim)

(set! temp-layer (car (gimp-layer-copy work-layer 0)))
(gimp-item-set-name temp-layer "Work layer")
(gimp-image-insert-layer new-img temp-layer 0 -1)
(gimp-item-transform-scale temp-layer 0 0 dim dim 0 2 1 3 0)
)

; We don't do the biggest size at this moment
(map resize-to-dim '(16 32 48 64 72 96 128))

; Create the big layer, but do not add it yet
(set! big-layer (car (gimp-layer-copy work-layer 0)))
(gimp-item-set-name big-layer "Big")

; We can now get rid of the working layer
(gimp-image-remove-layer new-img work-layer)

; These two functions allow us to create new layers which are
; clones of the existing ones but at different color depths.
; We have to use two functions and pass through intermediate
; images because otherwise the second color reduction would dupe
; the layers, thus giving an unneeded extra set of layers
; TODO a potential study should be done on whether it's better
; to go straight to the lowest number of color (as we do), or
; passing through intermediate number of colors.
; Observe that no dithering is done. This is intentional, since
; it gives the best results.
(define (palettize-image num)
(set! temp-img (car (gimp-image-duplicate new-img)))
(gimp-image-convert-indexed temp-img 0 0 num TRUE TRUE "")
temp-img)
(define (plop-image temp-img)
(set! layers (gimp-image-get-layers temp-img))
(set! layernum (car layers))
(set! layers-array (cadr layers))
(while (> layernum 0)
(set! layer (car
(gimp-layer-new-from-drawable
(aref layers-array (- layernum 1)) new-img)
)
)
(gimp-image-insert-layer new-img layer 0 -1)
(set! layernum (- layernum 1))
)
(gimp-image-delete temp-img)
)

; The 256 color image
;(set! eigth-bit (palettize-image 256))
; RC: Use 15 instead of 16 for the transparency
;(set! four-bit (palettize-image 15))

; Now we put the new layers back in the original image
;(plop-image eigth-bit)
;(plop-image four-bit)

; We add the big version
(gimp-image-insert-layer new-img big-layer 0 -1)
(gimp-item-transform-scale big-layer 0 0 256 256 0 2 1 3 0)

; We display the new image
(gimp-display-new new-img)

; And we flush the display
(gimp-displays-flush)
))

; TODO the plugin currently only works with truecolor images
; it could be extended to work with palettized images, thus only creating
; layers for depths up to the current image depth
(script-fu-register "script-fu-iconify"
"Iconify"
"Use the current layer of the current image to create a multi-sized, multi-depth Windows icon file"
"Giuseppe Bilotta, Fixed By Roland Clobus for gimp 2.8+ and then Fixed By GlitchyPies for gimp 2.99.8+ Ace Of Snakes try to fix for gimp 3.0.0"
"Giuseppe Bilotta, Fixed By Roland Clobus for gimp 2.8+ and then Fixed By GlitchyPies for gimp 2.99.8+ Ace Of Snakes try to fix for gimp 3.0.0"
"20051021"
"RGB*"
SF-IMAGE "Image to iconify" 0
SF-DRAWABLE "Layer to iconify" 0)

(script-fu-menu-register "script-fu-iconify" "<Image>/Script-Fu/Utils")
