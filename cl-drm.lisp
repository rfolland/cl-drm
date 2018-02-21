(in-package :drm)

(define-foreign-library libdrm
  (t (:default "libdrm")))

(use-foreign-library libdrm)

(defcfun ("drmIoctl" ioctl) :int
  (fd :int)
  (request :unsigned-long)
  (data :pointer))

(defcvar "errno" :int)

(defcfun strerror :string
  (error :int))

(defconstant DRM_IOCTL_MODE_CREATE_DUMB  #xc02064b2)
(defconstant DRM_IOCTL_MODE_MAP_DUMB     #xc01064b3)
(defconstant DRM_IOCTL_MODE_DESTROY_DUMB #xc00464b4)

(defun fourcc-code (set)
  (when (equal 4 (length set))
    (logior (ash (char-code (fourth set)) 24)
            (ash (char-code (third set)) 16)
            (ash (char-code (second set)) 8)
            (char-code (first set)))))

(defconstant DRM_FORMAT_XRGB8888 (fourcc-code '(#\X #\R #\2 #\4))) ;[31:0] x:R:G:B 8:8:8:8 little endian
;; #define DRM_FORMAT_XBGR8888	fourcc_code('X', 'B', '2', '4') /* [31:0] x:B:G:R 8:8:8:8 little endian */
;; #define DRM_FORMAT_RGBX8888	fourcc_code('R', 'X', '2', '4') /* [31:0] R:G:B:x 8:8:8:8 little endian */
;; #define DRM_FORMAT_BGRX8888	fourcc_code('B', 'X', '2', '4') /* [31:0] B:G:R:x 8:8:8:8 little endian */
(defconstant DRM_FORMAT_YUYV (fourcc-code '(#\Y #\U #\Y #\V))) ;[31:0] Cr0:Y1:Cb0:Y0 8:8:8:8 little endian
;; #define DRM_FORMAT_YVYU  fourcc_code('Y', 'V', 'Y', 'U') /* [31:0] Cb0:Y1:Cr0:Y0 8:8:8:8 little endian */
;; #define DRM_FORMAT_UYVY  fourcc_code('U', 'Y', 'V', 'Y') /* [31:0] Y1:Cr0:Y0:Cb0 8:8:8:8 little endian */
;; #define DRM_FORMAT_VYUY  fourcc_code('V', 'Y', 'U', 'Y') /* [31:0] Y1:Cb0:Y0:Cr0 8:8:8:8 little endian */

(defcenum mode-connection
  (:connected 1)
  (:disconnected 2)
  (:unknown-connection 3))

(defcenum mode-subpixel
  (:unknown 1)
  :horizontal-rgb
  :horizontal-bgr
  :vertical-rgb
  :vertical-bgr
  :none)

(defcenum ioctl-request
  (:mode-create-dumb #xb2)
  (:mode-map-dumb #xb3)
  (:mode-destroy-dumb #xb4))

(defcstruct mode-property-enum
  (value :uint64)
  (name :char :count 32))

(defcstruct mode-res 
  (count-fbs :int)
  (fbs (:pointer :uint32))
  (count-crtcs :int)
  (crtcs (:pointer :uint32))
  (count-connectors :int)
  (connectors (:pointer :uint32))
  (count-encoders :int)
  (encoders :uint32)
  (min-width :uint32)
  (max-width :uint32)
  (min-height :uint32)
  (max-height :uint32))

(defcstruct mode-mode-info
  (clock :uint32)
  (hdisplay :uint16)
  (hsync-start :uint16)
  (hsync-end :uint16)
  (htotal :uint16)
  (hskew :uint16)
  (vdisplay :uint16)
  (vsync-start :uint16)
  (vsync-end :uint16)
  (vtotal :uint16)
  (vskew :uint16)
  (vrefresh :uint16)
  (flags :uint32)
  (type :uint32)
  (name :char :count 32))

(defun mode-mode-info-get-clock (mode)
  (foreign-slot-value mode '(:struct drm:mode-mode-info) 'clock))

(defcstruct mode-property
  (prop-id :uint32)
  (flags :uint32)
  (name :char :count 32)
  (count-values :int)
  (values (:pointer :uint64))
  (count-enums :int)
  (enums (:pointer (:struct mode-property-enum)))
  (count-blobs :int)
  (blob-ids (:pointer :uint32)))

(defcstruct mode-property-blob
  (id :uint32)
  (length :uint32)
  (data :pointer))

(defcstruct mode-connector
  (connector-id :uint32)
  (encoder-id :uint32)
  (connector-type :uint32)
  (connector-type-id :uint32)
  (connection mode-connection)
  (mm-width :uint32)
  (mm-height :uint32)
  (subpixel mode-subpixel)
  (count-modes :int) ;; defined as just int
  (modes (:pointer (:struct mode-mode-info)))
  (count-props :int) ;; defined as just int
  (props (:pointer :uint32))
  (prop-values (:pointer :uint64))
  (count-encoders :int)
  (encoders (:pointer :uint32)))

(defun drm-mode-create-dumb-set-width (req width)
  (setf (foreign-slot-value req '(:struct drm:drm-mode-create-dumb) 'width) width))

(defun drm-mode-create-dumb-set-height (req height)
  (setf (foreign-slot-value req '(:struct drm:drm-mode-create-dumb) 'height) height))

(defun drm-mode-create-dumb-set-bpp (req bpp)
  (setf (foreign-slot-value req '(:struct drm:drm-mode-create-dumb) 'bpp) bpp))

(defun drm-mode-create-dumb-get-pitch (req)
  (foreign-slot-value req '(:struct drm:drm-mode-create-dumb) 'pitch))

(defun drm-mode-create-dumb-get-size (req)
  (foreign-slot-value req '(:struct drm:drm-mode-create-dumb) 'size))

(defun drm-mode-create-dumb-get-handle (req)
  (foreign-slot-value req '(:struct drm:drm-mode-create-dumb) 'handle))

(defcstruct drm-mode-create-dumb
  (height :uint32)
  (width :uint32)
  (bpp :uint32)
  (flags :uint32)
  (handle :uint32)
  (pitch :uint32)
  (size :uint64))

(defcstruct drm-mode-map-dumb
  (handle :uint32)
  (pad :uint32)
  (offset :uint64))

(defun drm-mode-map-dumb-set-handle (req handle)
  (setf (foreign-slot-value req '(:struct drm:drm-mode-map-dumb) 'handle) handle))

(defun drm-mode-map-dumb-get-offset (req)
  (foreign-slot-value req '(:struct drm:drm-mode-map-dumb) 'offset))

(defcstruct drm-mode-destroy-dumb
  (handle :uint32))

(defcstruct mode-encoder
  (encoder-id :uint32)
  (encoder-type :uint32)
  (crtc-id :uint32)
  (possible-crtcs :uint32)
  (possible-clones :uint32))

(defcfun ("drmModeGetEncoder" mode-get-encoder) :pointer
  (fd :int)
  (encoder-id :uint32))

(defcfun ("drmModeGetResources" mode-get-resources) (:pointer (:struct mode-res))
  (fd :int))

(defcfun ("drmModeGetCrtc" mode-get-crtc) (:pointer (:struct mode-crtc))
  (fd :int)
  (crtc-id :uint32))

(defcfun ("drmModeGetConnector" mode-get-connector) (:pointer (:struct mode-connector))
  (fd :int)
  (connector-id :uint32))

(defcfun ("drmModeGetConnectorCurrent" mode-get-connector-current) (:pointer (:struct mode-connector))
  (fd :int)
  (connector-id :uint32))

(defcfun ("drmModeGetProperty" mode-get-property) (:pointer (:struct mode-property))
  (fd :int)
  (property-id :uint32))

(defcfun ("drmModeGetPropertyBlob" mode-get-property-blob) (:pointer (:struct mode-property-blob))
  (fd :int)
  (blob-id :uint32))

(defun get-connectors (fd)
  (let* ((resources (mode-get-resources fd))
         (count (foreign-slot-value resources '(:struct mode-res) 'count-connectors))
         (ptr (foreign-slot-value resources '(:struct mode-res) 'connectors)))
    (mapcar (lambda (connector-id) (mode-get-connector fd connector-id))
            (loop :for i :from 0 :to (- count 1)
               :collecting (mem-aref ptr :uint32 i)))))

(defun get-framebuffers (fd)
  (let* ((resources (mode-get-resources fd))
         (count (foreign-slot-value resources '(:struct mode-res) 'count-fbs))
         (ptr (foreign-slot-value resources '(:struct mode-res) 'fbs)))
    (mapcar (lambda (connector-id)
              (mode-get-connector fd connector-id))
            (loop :for i :from 0 :to (- count 1)
               :collecting (mem-aref ptr :uint32 i)))))

(defun find-connectors (fd resources)
  (let ((count (foreign-slot-value resources '(:struct mode-res) 'count-connectors))
	(ptr (foreign-slot-value resources '(:struct mode-res) 'connectors)))
    (mapcar (lambda (connector-id)
	      (mode-get-connector fd connector-id))
	    (loop :for i :from 0 :to (- count 1)
	       :collecting (mem-aref ptr :uint32 i)))))

(defun first-connected (connectors)
  (loop :for connector :in connectors
     :when (eql (foreign-slot-value connector '(:struct mode-connector) 'connection) :connected)
     :return connector))

(defun find-encoder (fd connector)
  (let ((encoder-id (foreign-slot-value connector '(:struct mode-connector) 'encoder-id)))
    (if (zerop encoder-id)
	(error "No encoder found")
	(mode-get-encoder fd encoder-id))))

(defun get-modes (connector)
  (let ((count-modes (foreign-slot-value connector '(:struct mode-connector)  'count-modes))
	(modes (foreign-slot-value connector '(:struct mode-connector) 'modes)))
    (loop :for i :from 0 :to (- count-modes 1)
       :collecting (mem-aptr modes '(:struct mode-mode-info) i))))

(defcstruct mode-crtc
  (crtc-id :uint32)
  (buffer-id :uint32)
  (x :uint32)
  (y :uint32)
  (width :uint32)
  (height :uint32)
  (mode-valid :int)
  (mode (:struct mode-mode-info))
  (gamma-size :int))

(defcfun ("drmModeGetCrtc" mode-get-crtc) (:pointer (:struct mode-crtc))
  (fd :int)
  (crtc-id :uint32))

(defun mode-crtc-get-crtc-id (crtc)
  (cffi:foreign-slot-value crtc '(:struct mode-crtc) 'crtc-id))

(defun mode-crtc-get-buffer-id (crtc)
  (cffi:foreign-slot-value crtc '(:struct mode-crtc) 'buffer-id))

(defun mode-crtc-get-x (crtc)
  (cffi:foreign-slot-value crtc '(:struct mode-crtc) 'x))

(defun mode-crtc-get-y (crtc)
  (cffi:foreign-slot-value crtc '(:struct mode-crtc) 'y))

(defun mode-crtc-get-mode (crtc)
  (cffi:foreign-slot-pointer crtc '(:struct mode-crtc) 'mode))

(defun connected-p (connector)
  (eql (foreign-slot-value connector '(:struct mode-connector) 'connection) :connected))

(defun find-encoder (fd connector)
  (let ((encoder-id (foreign-slot-value connector '(:struct mode-connector) 'encoder-id)))
    (if (zerop encoder-id)
        (error "No encoder found")
        (mode-get-encoder fd encoder-id))))

(defun get-res-count-crtcs (res)
  (foreign-slot-value res '(:struct mode-res) 'count-crtcs))

(defun get-res-crtc (res index)
  (mem-aref (foreign-slot-value res '(:struct mode-res) 'crtcs) :uint32 index))

(defun get-connector-id (connector)
  (foreign-slot-value connector '(:struct mode-connector) 'connector-id))

(defun get-connector-encoder-id (connector)
  (foreign-slot-value connector '(:struct mode-connector) 'encoder-id))

(defun set-drm-mode-create-dumb-width (dumb width)
  (setf (foreign-slot-value dumb '(:struct drm-mode-create-dumb) 'width) width))

(defun set-drm-mode-create-dumb-height (dumb height)
  (setf (foreign-slot-value dumb '(:struct drm-mode-create-dumb) 'height) height))

(defun set-drm-mode-create-dumb-bpp (dumb bpp)
  (setf (foreign-slot-value dumb '(:struct drm-mode-create-dumb) 'bpp) bpp))

(defun drm-mode-destroy-dumb-set-handle (req handle)
  (setf (foreign-slot-value req '(:struct drm-mode-destroy-dumb) 'handle) handle))

(defun get-connector-encoders (connector)
  (let ((count-encoders (foreign-slot-value connector '(:struct mode-connector) 'count-encoders))
        (encoders (foreign-slot-value connector '(:struct mode-connector) 'encoders)))
    (loop :for i :from 0 :to (- count-encoders 1)
       :collecting (mem-aref encoders :uint32 i))))

(defun get-connector-count-encoders (connector)
  (foreign-slot-value connector '(:struct mode-connector) 'count-encoders))

(defun get-connector-count-props (connector)
  (foreign-slot-value connector '(:struct mode-connector) 'count-props))

(defun get-property-count-blobs (prop)
  (foreign-slot-value prop '(:struct mode-property) 'count-blobs))

(defun get-property-blob-id (prop index)
  (mem-aref (foreign-slot-value prop '(:struct mode-property) 'count-blobs) :uint32 index))

(defun get-connector-property (fd connector index)
  (mode-get-property fd (mem-aref (foreign-slot-value connector '(:struct mode-connector)
                                                      'props) :uint32 index)))

(defun get-blob-id (blob)
  (foreign-slot-value blob '(:struct mode-property-blob) 'id))

(defun get-blob-data (blob)
  (let (data)
    (dotimes (n (foreign-slot-value blob '(:struct mode-property-blob) 'length))
      (push (mem-aref (foreign-slot-value blob '(:struct mode-property-blob) 'data) :uint8 n) data))
    (reverse data)))

(defun get-connector-prop-value (connector index)
  (mem-aref (foreign-slot-value connector '(:struct mode-connector) 'prop-values) :uint64 index))

(defun get-connector-prop-id (fd connector prop-name)
  (let (prop-id
        done)
    (dotimes (n (get-connector-count-props connector))
      (unless done
        (let ((prop (mode-get-property
                     fd (mem-aref (foreign-slot-value connector '(:struct mode-connector) 'props) :uint32 n))))
          (when (string-equal prop-name (get-property-name prop))
            (setf prop-id (get-property-id prop))
            (setf done t)))))
    prop-id))

(defun get-property-id (prop)
  (foreign-slot-value prop '(:struct mode-property) 'prop-id))

(defun get-property-name (prop)
  (foreign-slot-value prop '(:struct mode-property) 'name))

(defun get-encoder-id (encoder)
  (foreign-slot-value encoder '(:struct mode-encoder) 'encoder-id))

(defun get-encoder-crtc-id (encoder)
  (foreign-slot-value encoder '(:struct mode-encoder) 'crtc-id))

(defun get-encoder-possible-crtcs (encoder)
  (foreign-slot-value encoder '(:struct mode-encoder) 'possible-crtcs))

(defun get-modes (connector)
  (let ((count-modes (foreign-slot-value connector '(:struct mode-connector)  'count-modes))
        (modes (foreign-slot-value connector '(:struct mode-connector) 'modes)))
    (loop :for i :from 0 :to (- count-modes 1)
       :collecting (mem-aptr modes '(:struct mode-mode-info) i))))

(defun get-connector-count-modes (connector)
  (foreign-slot-value connector '(:struct mode-connector)  'count-modes))

(defun get-connector-mode (connector index)
  (let ((count-modes (foreign-slot-value connector '(:struct mode-connector)  'count-modes))
        (modes (foreign-slot-value connector '(:struct mode-connector) 'modes)))
    (unless (> index count-modes)
      (mem-aptr modes '(:struct mode-mode-info) index))))

(defun get-mode-clock (mode)
  (foreign-slot-value mode '(:struct mode-mode-info) 'clock))

(defun get-mode-vrefresh (mode)
  (foreign-slot-value mode '(:struct mode-mode-info) 'vrefresh))

(defun get-mode-flags (mode)
  (foreign-slot-value mode '(:struct mode-mode-info) 'flags))

(defun mode-preferred-p (mode)
  (not (zerop (logand #b00001000 (foreign-slot-value mode '(:struct mode-mode-info) 'flags)))))

(defun get-mode-name (mode)
  (foreign-slot-value mode '(:struct mode-mode-info) 'name))

(defun get-props (connector)
  (let ((count-props (foreign-slot-value connector '(:struct mode-connector)  'count-props))
        (props (foreign-slot-value connector '(:struct mode-connector) 'props)))
    (loop :for i :from 0 :to (- count-props 1)
       :collecting (mem-aref props :uint32 i))))

(defcfun ("drmModeFreeEncoder" mode-free-encoder) :void
  (encoder (:pointer (:struct mode-encoder))))

(defcfun ("drmModeFreeConnector" mode-free-connector) :void
  (connector (:pointer (:struct mode-connector))))

(defcfun ("drmModeFreeResources" mode-free-resources) :void
  (resources (:pointer (:struct mode-res))))

(defcfun ("drmModeFreeCrtc" mode-free-crtc) :void
  (crtc (:pointer (:struct mode-crtc))))

(defcfun ("drmModeSetCrtc" mode-set-crtc) :int
  (fd :int)
  (crtc-id :uint32)
  (buffer-id :uint32)
  (x :uint32)
  (y :uint32)
  (connectors (:pointer :uint32))
  (count :int)
  (mode (:pointer (:struct mode-mode-info))))

(defclass display-config ()
  ((connector-id :accessor connector-id :initarg :connector-id :initform nil)
   (mode-info :accessor mode-info :initarg :mode-info :initform nil)
   (crtc :accessor crtc :initarg :crtc :initform nil)))

(defun find-display-configuration (fd)
  (let* ((resources (mode-get-resources fd))
	 (connector (first-connected (find-connectors fd resources)))
	 (connector-id (foreign-slot-value connector '(:struct mode-connector) 'connector-id))
	 (mode (first (get-modes connector)))
	 (encoder (find-encoder fd connector))
	 (crtc (mode-get-crtc fd (foreign-slot-value encoder '(:struct mode-encoder) 'crtc-id))))
    (format t "resolution: ~dx~d~%"
	    (foreign-slot-value mode '(:struct mode-mode-info) 'hdisplay)
	    (foreign-slot-value mode '(:struct mode-mode-info) 'vdisplay))
    ;(mode-free-encoder encoder)
    ;(mode-free-connector connector)
    ;; BUG? (mode-free-connector connector)
    ;; if we free the connector the mode is corrupted on return from this function
    ;(mode-free-resources resources)
    (make-instance 'display-config
		   :connector-id connector-id
		   :mode-info mode
		   :crtc crtc)))

(defun get-mode-info-hdisplay (mode)
  (foreign-slot-value mode '(:struct mode-mode-info) 'hdisplay))

(defun get-mode-info-vdisplay (mode)
  (foreign-slot-value mode '(:struct mode-mode-info) 'vdisplay))

(defcstruct mode-fb
  (fb-id :uint32)
  (width :uint32)
  (height :uint32)
  (pitch :uint32)
  (bpp :uint32)
  (depth :uint32)
  (handle :uint32))

(defcfun ("drmModeGetFB" mode-get-fb) (:pointer (:struct mode-fb))
  (fd :int)
  (buffer-id :uint32))

(defcfun ("drmModeAddFB" mode-add-framebuffer) :int
  (fd :int)
  (width :uint32)
  (height :uint32)
  (depth :uint8)
  (bpp :uint8)
  (pitch :uint32)
  (bo-handle :uint32)
  (buf-id (:pointer :uint32)))

(defcfun ("drmModeAddFB2" mode-add-framebuffer-2) :int
  (fd :int)
  (width :uint32)
  (height :uint32)
  (pixel-format :uint32)
  (bo-handles :pointer)
  (pitches :pointer)
  (offsets :pointer)
  ;; (bo-handles (:pointer :uint32))
  ;; (pitches (:pointer :uint32))
  ;; (offsets (:pointer :uint32))
  (buf-id (:pointer :uint32))
  (flags :uint32))

(defcfun ("drmModeRmFB" mode-remove-framebuffer) :int
  (fd :int)
  (buffer-id :uint32))

(defcfun ("drmModePageFlip" mode-page-flip) :int
  (fd :int)
  (crtc-id :uint32)
  (fb-id :uint32)
  (flags :uint32)
  (user-data :pointer))

(defcfun ("drmModeConnectorSetProperty" mode-connector-set-property) :int
  (fd :int)
  (connector-id :uint32)
  (property-id :uint32)
  (value :uint64))

;; void (*vblank_handler)(int fd, unsigned int sequence, unsigned int tv_sec, unsigned int tv_usec, void *user_data);
;; void (*page_flip_handler)(int fd, unsigned int sequence, unsigned int tv_sec, unsigned int tv_usec, void *user_data);
(defcstruct event-context
  (version :int)
  (vblank-handler :pointer) 
  (page-flip-handler :pointer))

(defcfun ("drmHandleEvent" handle-event) :int
  (fd :int)
  (event-context (:pointer (:struct event-context))))
