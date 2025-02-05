; ---------------------------------------------------------------------------
; Object 48 - ball on a	chain that Eggman swings (GHZ)

; spawned by:
;	BossGreenHill - routine 0
;	BossBall - routines 6 (chain), 8 (ball)
; ---------------------------------------------------------------------------

BossBall:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	GBall_Index(pc,d0.w),d1
		jmp	GBall_Index(pc,d1.w)
; ===========================================================================
GBall_Index:	index *,,2
		ptr GBall_Main
		ptr GBall_Base
		ptr GBall_Base2
		ptr GBall_Link
		ptr GBall_Ball

		rsobj BossBall
ist_ball_child_list:	rs.b 6
ost_ball_boss_dist:	rs.w 1					; distance of base from boss (2 bytes)
ost_ball_base_y_pos:	rs.w 1					; y position of base (2 bytes)
ost_ball_base_x_pos:	rs.w 1					; x position of base (2 bytes)
ost_ball_radius:	rs.b 1					; distance of ball/link from base
ost_ball_side:		rs.b 1					; which side the ball is on - 0 = right; 1 = left
ost_ball_speed:		rs.w 1					; rate of change of angle (2 bytes)
		rsobjend
; ===========================================================================

GBall_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto GBall_Base next
		move.w	#$4080,ost_angle(a0)
		move.w	#-$200,ost_ball_speed(a0)
		move.l	#Map_BossItems,ost_mappings(a0)
		move.w	#vram_weapon/sizeof_cell,ost_tile(a0)
		moveq	#id_UPLC_GHZAnchor,d0
		jsr	UncPLC
		lea	ost_subtype(a0),a2
		move.b	#0,(a2)+
		moveq	#5,d1					; load 5 additional objects
		movea.l	a0,a1					; replace current object with chain base
		bra.s	.chain_base
; ===========================================================================

	.loop:
		jsr	(FindNextFreeObj).l			; find free OST slot
		bne.s	.fail					; branch if not found
		move.w	ost_x_pos(a0),ost_x_pos(a1)
		move.w	ost_y_pos(a0),ost_y_pos(a1)
		move.l	#BossBall,ost_id(a1)			; load chain link object
		move.b	#id_GBall_Link,ost_routine(a1)
		move.l	#Map_Swing_GHZ,ost_mappings(a1)
		move.w	(v_tile_swing).w,ost_tile(a1)
		move.b	#id_frame_swing_chain,ost_frame(a1)
		addq.b	#1,ost_subtype(a0)			; increment parent's subtype (ends up being 5)

.chain_base:
		move.w	a1,d5					; address of current OST
		subi.w	#v_ost_all&$FFFF,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5					; convert address to OST index
		move.b	d5,(a2)+				; add to list in parent OST
		move.b	#render_rel,ost_render(a1)
		move.b	#8,ost_displaywidth(a1)
		move.b	#6,ost_priority(a1)
		move.w	ost_parent(a0),ost_parent(a1)
		dbf	d1,.loop				; repeat sequence 5 more times

	.fail:
		move.b	#id_GBall_Ball,ost_routine(a1)
		move.l	#Map_GBall,ost_mappings(a1)		; replace last object with ball
		move.w	#(vram_ball/sizeof_cell)+tile_pal3,ost_tile(a1)
		move.b	#id_frame_ball_check1,ost_frame(a1)
		move.b	#5,ost_priority(a1)
		move.b	#id_col_20x20+id_col_hurt,ost_col_type(a1) ; make object hurt Sonic
		rts	
; ===========================================================================

GBall_PosData:	; distances of objects from base
		dc.b 0						; base
		dc.b $10, $20, $30, $40				; chain links
		dc.b $60					; ball

; ===========================================================================

GBall_Base:	; Routine 2
		lea	(GBall_PosData).l,a3
		lea	ost_subtype(a0),a2
		moveq	#0,d6
		move.b	(a2)+,d6				; get number of child objects

	.loop:
		moveq	#0,d4
		move.b	(a2)+,d4				; get child object OST index
		lsl.w	#6,d4
		addi.l	#v_ost_all&$FFFFFF,d4
		movea.l	d4,a1					; convert to RAM address
		move.b	(a3)+,d0				; get target distance from base
		cmp.b	ost_ball_radius(a1),d0			; has object reached target?
		beq.s	.reached_dist				; if yes, branch
		addq.b	#1,ost_ball_radius(a1)			; increment distance

	.reached_dist:
		dbf	d6,.loop				; repeat for all children

		cmp.b	ost_ball_radius(a1),d0			; has final object (ball) reached target?
		bne.s	.not_finished				; if not, branch
		getparent
		cmpi.b	#id_BGHZ_ChgDir,ost_mode(a1)	; is boss in back-and-forth phase?
		bne.s	.not_finished				; if not, branch
		addq.b	#2,ost_routine(a0)			; goto GBall_Base2 next

	.not_finished:
		cmpi.w	#$20,ost_ball_boss_dist(a0)		; has base moved an additional 32px? (aligned with bottom of ship)
		beq.s	.reached_dist2				; if yes, branch
		addq.w	#1,ost_ball_boss_dist(a0)		; increment distance

	.reached_dist2:
		bsr.w	GBall_UpdateBase			; update base animation/position
		move.b	ost_angle(a0),d0
		jsr	(GBall_MoveAll).l			; update positions of all chain links & ball
		jmp	(DisplaySprite).l
; ===========================================================================

GBall_Base2:	; Routine 4
		bsr.w	GBall_UpdateBase			; update base animation/position
		jsr	(GBall_Move).l				; update angle and positions of child objects
		jmp	(DisplaySprite).l

; ---------------------------------------------------------------------------
; Subroutine to animate, update position and destroy base
; ---------------------------------------------------------------------------

GBall_UpdateBase:
		getparent					; get address of OST of parent
		addi.b	#$20,ost_anim_frame(a0)			; increment frame counter
		bcc.s	.no_chg					; branch if byte doesn't wrap from $C0 to 0
		bchg	#0,ost_frame(a0)			; change frame every 8th frame

	.no_chg:
		move.w	ost_x_pos(a1),ost_ball_base_x_pos(a0)	; get position from parent (ship)
		move.w	ost_y_pos(a1),d0
		add.w	ost_ball_boss_dist(a0),d0
		move.w	d0,ost_ball_base_y_pos(a0)
		move.b	ost_status(a1),ost_status(a0)
		tst.b	ost_status(a1)				; has boss been beaten?
		bpl.s	.not_beaten				; if not, branch
		move.l	#ExplosionBomb,ost_id(a0)		; replace base with explosion object
		move.b	#id_ExBom_Main,ost_routine(a0)

	.not_beaten:
		rts	
; End of function GBall_UpdateBase

; ===========================================================================

GBall_Link:	; Routine 6
		getparent					; get address of OST of parent (ship)
		tst.b	ost_status(a1)				; has boss been beaten?
		bpl.s	.not_beaten				; if not, branch
		move.l	#ExplosionBomb,ost_id(a0)		; replace chain with explosion object
		move.b	#id_ExBom_Main,ost_routine(a0)

	.not_beaten:
		jmp	(DisplaySprite).l
; ===========================================================================

GBall_Ball:	; Routine 8
		lea	(Ani_Ball).l,a1
		bsr.w	AnimateSprite
		set_dma_dest vram_ball,d1			; set VRAM address to write gfx
		bsr.w	DPLCSprite				; write gfx if frame has changed
		
		getparent					; get address of OST of parent (ship)
		tst.b	ost_status(a1)				; has boss been beaten?
		bpl.s	.display				; if not, branch
		move.b	#0,ost_col_type(a0)			; make ball harmless
		jsr	BossExplode				; spawn explosions
		subq.b	#1,ost_ball_radius(a0)			; use radius as timer, decrements from 96
		bpl.s	.display				; branch if time remains
		move.l	#ExplosionBomb,ost_id(a0)		; replace ball with explosion after 1.5 seconds
		move.b	#id_ExBom_Main,ost_routine(a0)

	.display:
		jmp	(DisplaySprite).l

; ---------------------------------------------------------------------------
; Animation script
; ---------------------------------------------------------------------------

Ani_Ball:	index *
		ptr ani_ball_boss
		
ani_ball_boss:
		dc.w 0
		dc.w id_frame_ball_shiny
		dc.w id_frame_ball_check1
		dc.w id_Anim_Flag_Restart
		even

; ---------------------------------------------------------------------------
; Subroutine to update swinging angle and positions for chain links and ball
; ---------------------------------------------------------------------------

GBall_Move:
		tst.b	ost_ball_side(a0)			; is ball on the left side of the screen?
		bne.s	.left_side				; if yes, branch
		move.w	ost_ball_speed(a0),d0
		addq.w	#8,d0
		move.w	d0,ost_ball_speed(a0)			; increase swing speed
		add.w	d0,ost_angle(a0)			; update angle
		cmpi.w	#$200,d0				; is speed at max?
		bne.s	.not_at_highest				; if not, branch
		move.b	#1,ost_ball_side(a0)			; switch side flag
		bra.s	.not_at_highest
; ===========================================================================

	.left_side:
		move.w	ost_ball_speed(a0),d0
		subq.w	#8,d0
		move.w	d0,ost_ball_speed(a0)			; decrease swing speed
		add.w	d0,ost_angle(a0)			; update angle
		cmpi.w	#-$200,d0				; is speed at max?
		bne.s	.not_at_highest				; if not, branch
		move.b	#0,ost_ball_side(a0)			; switch side flag

	.not_at_highest:
		move.b	ost_angle(a0),d0			; get latest angle
		;bra.w	GBall_MoveAll

; ---------------------------------------------------------------------------
; Subroutine to convert angle to position for all chain links

; input:
;	d0 = current swing angle
; ---------------------------------------------------------------------------

GBall_MoveAll:
		bsr.w	CalcSine				; convert d0 to sine
		move.w	ost_ball_base_y_pos(a0),d2
		move.w	ost_ball_base_x_pos(a0),d3
		lea	ost_subtype(a0),a2			; (a2) = chain length, followed by child OST index list
		moveq	#0,d6
		move.b	(a2)+,d6				; get chain length

	.loop:
		moveq	#0,d4
		move.b	(a2)+,d4				; get child OST index
		lsl.w	#6,d4
		addi.l	#v_ost_all&$FFFFFF,d4			; convert to RAM address
		movea.l	d4,a1
		moveq	#0,d4
		move.b	ost_ball_radius(a1),d4			; get distance of object from anchor
		move.l	d4,d5
		muls.w	d0,d4
		asr.l	#8,d4
		muls.w	d1,d5
		asr.l	#8,d5
		add.w	d2,d4
		add.w	d3,d5
		move.w	d4,ost_y_pos(a1)			; update position
		move.w	d5,ost_x_pos(a1)
		dbf	d6,.loop				; repeat for all chainlinks and platform
		rts		
