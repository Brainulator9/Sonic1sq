; ---------------------------------------------------------------------------
; Object 4E - advancing	wall of	lava (MZ)

; spawned by:
;	ObjPos_MZ2 - subtype 0
;	LavaWall
; ---------------------------------------------------------------------------

LavaWall:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	LWall_Index(pc,d0.w),d1
		jmp	LWall_Index(pc,d1.w)
; ===========================================================================
LWall_Index:	index *,,2
		ptr LWall_Main
		ptr LWall_Solid
		ptr LWall_Action
		ptr LWall_BackHalf
		ptr LWall_Delete

		rsobj LavaWall
ost_lwall_flag:		rs.b 1 ; $36				; flag to start wall moving
ost_lwall_parent:	rs.l 1 ; $3C				; address of OST of parent object (4 bytes)
		rsobjend
; ===========================================================================

LWall_Main:	; Routine 0
		addq.b	#id_LWall_Action,ost_routine(a0)	; goto LWall_Action next
		movea.l	a0,a1
		moveq	#1,d1
		bra.s	.make
; ===========================================================================

	.loop:
		bsr.w	FindNextFreeObj				; find free OST slot
		bne.s	.fail					; branch if not found

.make:
		move.l	#LavaWall,ost_id(a1)			; load object
		move.l	#Map_LWall,ost_mappings(a1)
		move.w	#tile_Kos_Lava+tile_pal4,ost_tile(a1)
		move.b	#render_rel,ost_render(a1)
		move.b	#$50,ost_displaywidth(a1)
		move.w	ost_x_pos(a0),ost_x_pos(a1)
		move.w	ost_y_pos(a0),ost_y_pos(a1)
		move.b	#1,ost_priority(a1)
		move.b	#$28,ost_width(a1)
		move.b	#16,ost_height(a1)
		move.b	#id_ani_lavawall_0,ost_anim(a1)
		move.b	#id_col_64x32+id_col_hurt,ost_col_type(a1)
		move.l	a0,ost_lwall_parent(a1)

	.fail:
		dbf	d1,.loop				; repeat sequence once

		addq.b	#id_LWall_BackHalf,ost_routine(a1)	; goto LWall_BackHalf next (2nd object only)
		move.b	#id_frame_lavawall_back,ost_frame(a1)	; use back of lava wall frame

LWall_Action:	; Routine 4
		bsr.w	Range
		cmpi.w	#192,d1
		bcc.s	.movewall				; branch if Sonic is > 192px away
		cmpi.w	#96,d3
		bcc.s	.movewall				; branch if Sonic is > 96px away on y axis
		move.b	#1,ost_lwall_flag(a0)			; set object to move
		bra.s	LWall_Solid
; ===========================================================================

.movewall:
		tst.b	ost_lwall_flag(a0)			; is object set to move?
		beq.s	LWall_Solid				; if not, branch
		move.w	#$180,ost_x_vel(a0)			; set object speed
		subq.b	#2,ost_routine(a0)			; goto LWall_Solid next

LWall_Solid:	; Routine 2
		bsr.w	SolidObject
		cmpi.w	#$6A0,ost_x_pos(a0)			; has object reached $6A0 on the x-axis?
		bne.s	.animate				; if not, branch
		clr.w	ost_x_vel(a0)				; stop object moving
		clr.b	ost_lwall_flag(a0)

	.animate:
		lea	(Ani_LWall).l,a1
		bsr.w	AnimateSprite
		cmpi.b	#id_Sonic_Hurt,(v_ost_player+ost_routine).w ; is Sonic hurt or dead?
		bcc.s	.rangechk				; if yes, branch
		bsr.w	SpeedToPos				; update position

	.rangechk:
		tst.b	ost_lwall_flag(a0)			; is wall already moving?
		bne.s	.moving					; if yes, branch
		move.w	ost_x_pos(a0),d0
		bsr.w	CheckActive
		bne.s	.chkgone

	.moving:
		bra.w	DisplaySprite
; ===========================================================================

.chkgone:
		lea	(v_respawn_list).w,a2
		moveq	#0,d0
		move.b	ost_respawn(a0),d0
		bclr	#7,2(a2,d0.w)
		move.b	#id_LWall_Delete,ost_routine(a0)
		rts	
; ===========================================================================

LWall_BackHalf:	; Routine 6
		movea.l	ost_lwall_parent(a0),a1			; get OST address of parent (front half)
		cmpi.b	#id_LWall_Delete,ost_routine(a1)	; is parent set to delete?
		beq.s	LWall_Delete				; if yes, branch
		move.w	ost_x_pos(a1),ost_x_pos(a0)		; match x position
		subi.w	#$80,ost_x_pos(a0)			; move 128px to the left
		bra.w	DisplaySprite
; ===========================================================================

LWall_Delete:	; Routine 8
		bra.w	DeleteObject

; ---------------------------------------------------------------------------
; Animation script
; ---------------------------------------------------------------------------

Ani_LWall:	index *
		ptr ani_lavawall_0
		
ani_lavawall_0:	dc.w 9
		dc.w id_frame_lavawall_0
		dc.w id_frame_lavawall_1
		dc.w id_frame_lavawall_2
		dc.w id_frame_lavawall_3
		dc.w id_Anim_Flag_Restart
		even
