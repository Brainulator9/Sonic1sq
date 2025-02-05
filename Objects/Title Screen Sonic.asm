; ---------------------------------------------------------------------------
; Object 0E - Sonic on the title screen

; spawned by:
;	GM_Title
; ---------------------------------------------------------------------------

TitleSonic:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	TSon_Index(pc,d0.w),d1
		jmp	TSon_Index(pc,d1.w)
; ===========================================================================
TSon_Index:	index *,,2
		ptr TSon_Main
		ptr TSon_Delay
		ptr TSon_Move
		ptr TSon_Animate

		rsobj TitleSonic
ost_tson_time:	rs.b 1
		rsobjend
; ===========================================================================

TSon_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto TSon_Delay next
		move.w	#$F0,ost_x_pos(a0)
		move.w	#$DE,ost_y_screen(a0)			; position is fixed to screen
		move.l	#Map_TSon,ost_mappings(a0)
		move.w	#tile_Kos_TitleSonic+tile_pal2,ost_tile(a0)
		move.b	#1,ost_priority(a0)
		move.b	#29,ost_tson_time(a0)			; set time delay to 0.5 seconds
		lea	(Ani_TSon).l,a1
		bsr.w	AnimateSprite

TSon_Delay:	;Routine 2
		subq.b	#1,ost_tson_time(a0)			; decrement timer
		bpl.s	.wait					; if time remains, branch
		addq.b	#2,ost_routine(a0)			; goto TSon_Move next
		bra.w	DisplaySprite

	.wait:
		rts	
; ===========================================================================

TSon_Move:	; Routine 4
		subq.w	#8,ost_y_screen(a0)			; move Sonic up
		cmpi.w	#$96,ost_y_screen(a0)			; has Sonic reached final position?
		bne.s	.display				; if not, branch
		addq.b	#2,ost_routine(a0)			; goto TSon_Animate next

	.display:
		bra.w	DisplaySprite

		rts	
; ===========================================================================

TSon_Animate:	; Routine 6
		lea	(Ani_TSon).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite

		rts	

; ---------------------------------------------------------------------------
; Animation script
; ---------------------------------------------------------------------------

Ani_TSon:	index *
		ptr ani_tson_0
		
ani_tson_0:	dc.w 7
		dc.w id_frame_tson_0
		dc.w id_frame_tson_1
		dc.w id_frame_tson_2
		dc.w id_frame_tson_3
		dc.w id_frame_tson_4
		dc.w id_frame_tson_5
		dc.w id_frame_tson_wag1
		dc.w id_frame_tson_wag2
		dc.w id_Anim_Flag_Back, 2
		even
