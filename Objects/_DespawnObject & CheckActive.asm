; ---------------------------------------------------------------------------
; Routine to check if object is still on-screen: display if yes, delete if not

;	uses d0.l, d1.w, a1, a2
; ---------------------------------------------------------------------------

DespawnObject:
		move.w	ost_x_pos(a0),d0
		andi.w	#$FF80,d0				; round down to nearest $80
		move.w	(v_camera_x_pos).w,d1			; get screen position
		subi.w	#128,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0					; d0 = approx distance between object and screen (negative if object is left of screen)
		cmpi.w	#128+screen_width+192,d0
		bls.w	DisplaySprite				; display instead of despawn

		move.b	ost_respawn(a0),d0			; get respawn id
		beq.w	DeleteObject				; branch if not set
		andi.w	#$FF,d0
		lea	(v_respawn_list).w,a2
		bclr	#7,2(a2,d0.w)				; clear high bit of respawn entry (i.e. object was despawned not broken)
		bra.w	DeleteObject				; delete the object

; ---------------------------------------------------------------------------
; As above, but without checking the respawn table

; input:
;	d0.w = x position (DespawnQuick_AltX only)

;	uses d0.l, d1.w, a1
; ---------------------------------------------------------------------------

DespawnQuick:
		move.w	ost_x_pos(a0),d0
		
DespawnQuick_AltX:
		andi.w	#$FF80,d0				; round down to nearest $80
		move.w	(v_camera_x_pos).w,d1			; get screen position
		subi.w	#128,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0					; d0 = approx distance between object and screen (negative if object is left of screen)
		cmpi.w	#128+screen_width+192,d0
		bhi.w	DeleteObject				; delete if object moves off screen
		bra.w	DisplaySprite				; display instead of despawn

DespawnQuick_NoDisplay:
		move.w	ost_x_pos(a0),d0
		andi.w	#$FF80,d0				; round down to nearest $80
		move.w	(v_camera_x_pos).w,d1			; get screen position
		subi.w	#128,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0					; d0 = approx distance between object and screen (negative if object is left of screen)
		cmpi.w	#128+screen_width+192,d0
		bhi.w	DeleteObject				; delete if object moves off screen
		rts						; don't display

; ---------------------------------------------------------------------------
; As DespawnObject, but also deletes child objects

; input:
;	d0.w = x position (DespawnFamily_AltX only)

;	uses d0.l, d1.w, a1, a2
; ---------------------------------------------------------------------------

DespawnFamily:
		move.w	ost_x_pos(a0),d0
		
DespawnFamily_AltX:
		andi.w	#$FF80,d0				; round down to nearest $80
		move.w	(v_camera_x_pos).w,d1			; get screen position
		subi.w	#128,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0					; d0 = approx distance between object and screen (negative if object is left of screen)
		cmpi.w	#128+screen_width+192,d0
		bls.w	DisplaySprite				; display instead of despawn

	DespawnFamily_Delete:
		move.b	ost_respawn(a0),d0			; get respawn id
		beq.w	DeleteFamily				; branch if not set
		andi.w	#$FF,d0
		lea	(v_respawn_list).w,a2
		bclr	#7,2(a2,d0.w)				; clear high bit of respawn entry (i.e. object was despawned not broken)
		bra.w	DeleteFamily				; delete the object

DespawnFamily_NoDisplay:
		move.w	ost_x_pos(a0),d0
		andi.w	#$FF80,d0				; round down to nearest $80
		move.w	(v_camera_x_pos).w,d1			; get screen position
		subi.w	#128,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0					; d0 = approx distance between object and screen (negative if object is left of screen)
		cmpi.w	#128+screen_width+192,d0
		bhi.s	DespawnFamily_Delete			; delete if object moves off screen
		rts						; don't display

; ---------------------------------------------------------------------------
; Subroutine to check if object is within active space around the screen

; input:
;	d0.w = object x position

; output:
;	d0.l = 0 if on screen; 1 if off screen

;	uses d1.w

; usage:
;		bsr.w	CheckActive
;		bne.w	.offscreen				; branch if outside active area
; ---------------------------------------------------------------------------

CheckActive:
		andi.w	#$FF80,d0				; round down to nearest $80
		move.w	(v_camera_x_pos).w,d1			; get screen position
		subi.w	#128,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0					; d0 = approx distance between object and screen (negative if object is left of screen)
		cmpi.w	#128+screen_width+192,d0
		bhi.s	.offscreen				; branch if d0 is negative or higher than 640
		
		moveq	#0,d0
		rts
		
	.offscreen:
		moveq	#1,d0
		rts

; ---------------------------------------------------------------------------
; Subroutine to get the state of an object from v_respawn_list

; output:
;	d0.b = byte from v_respawn_list for current object

;	uses d0.l, a2

; usage:
;		bsr.w	GetState
;		bne.w	.remembered				; branch if anything was remembered
; ---------------------------------------------------------------------------

GetState:
		moveq	#0,d0
		move.b	ost_respawn(a0),d0
		beq.s	.exit					; branch if object isn't in the respawn table
		lea	(v_respawn_list+2).w,a2
		adda.w	d0,a2					; jump to relevant position in respawn table
		bclr	#7,(a2)					; clear the already-loaded flag
		move.b	(a2),d0					; get value
		
	.exit:
		rts

; ---------------------------------------------------------------------------
; Subroutine to save the state of an object in v_respawn_list

; output:
;	a2 = address in v_respawn_list for current object
;	(a2).b = state of current object

;	uses d0.l

; usage:
;		bsr.w	SaveState
;		beq.s	.not_found				; branch if not in respawn table
;		bset	#0,(a2)					; remember bit
; ---------------------------------------------------------------------------

SaveState:
		moveq	#0,d0
		move.b	ost_respawn(a0),d0
		beq.s	.exit					; branch if object isn't in the respawn table
		lea	(v_respawn_list+2).w,a2
		adda.w	d0,a2					; jump to relevant position in respawn table
		
	.exit:
		rts
		
; ---------------------------------------------------------------------------
; Subroutine to prevent duplicate objects being loaded

;	uses d0.l, a2
; ---------------------------------------------------------------------------

PreventDupe:
		moveq	#0,d0
		move.b	ost_respawn(a0),d0
		beq.s	.exit					; branch if object isn't in the respawn table
		lea	(v_respawn_list+2).w,a2
		adda.w	d0,a2					; jump to relevant position in respawn table
		bclr	#7,(a2)					; clear the already-loaded flag
		bset	#0,(a2)					; remember this was loaded
		beq.s	.exit					; branch if not previously loaded
		addq.l	#4,sp					; don't execute object code after leaving this subroutine
		bra.w	DeleteObject				; delete object if previously loaded
		
	.exit:
		rts
