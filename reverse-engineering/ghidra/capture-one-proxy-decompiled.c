/* __ZNK5Proxy7JPEG_XL17LoadGlobalVersionERjRNSt3__114basic_ifstreamIcNS2_11char_traitsIcEEEE @ 015292d8 */

undefined1
__ZNK5Proxy7JPEG_XL17LoadGlobalVersionERjRNSt3__114basic_ifstreamIcNS2_11char_traitsIcEEEE
          (undefined8 param_1,uint *param_2,long *param_3)

{
  char *pcVar1;
  int iVar2;
  long lVar3;
  char *pcVar4;
  undefined8 *puVar5;
  int extraout_w1;
  int extraout_w1_00;
  long *extraout_x1;
  undefined1 uVar6;
  byte *pbStack_180;
  byte *pbStack_178;
  undefined8 uStack_170;
  int iStack_164;
  undefined8 uStack_160;
  undefined8 uStack_158;
  undefined8 uStack_150;
  undefined8 uStack_148;
  undefined8 uStack_140;
  undefined8 uStack_138;
  undefined8 uStack_130;
  undefined8 uStack_128;
  undefined8 uStack_120;
  undefined8 uStack_118;
  undefined8 uStack_110;
  undefined8 uStack_108;
  undefined8 uStack_100;
  undefined8 uStack_f8;
  undefined8 uStack_f0;
  undefined8 uStack_e8;
  undefined8 uStack_e0;
  undefined8 auStack_d0 [16];
  ulong uStack_50;
  long lStack_48;

  lStack_48 = *(long *)PTR____stack_chk_guard_01d15188;
  pbStack_180 = (byte *)0x0;
  pbStack_178 = (byte *)0x0;
  uStack_170 = 0;
  if (((*(int *)((long)param_3 + *(long *)(*param_3 + -0x18) + 0x20) != 0) ||
      (__ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgExNS_8ios_base7seekdirE(param_3,0,2),
      *(int *)((long)param_3 + *(long *)(*param_3 + -0x18) + 0x20) != 0)) ||
     (__ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5tellgEv(auStack_d0,param_3),
     0x7ffffffffffffffe < uStack_50)) {
    uVar6 = 0x15;
    goto LAB_01529368;
  }
  uStack_e0 = 0;
  uStack_f8 = 0;
  uStack_100 = 0;
  uStack_e8 = 0;
  uStack_f0 = 0;
  uStack_118 = 0;
  uStack_120 = 0;
  uStack_108 = 0;
  uStack_110 = 0;
  uStack_138 = 0;
  uStack_140 = 0;
  uStack_128 = 0;
  uStack_130 = 0;
  uStack_158 = 0;
  uStack_160 = 0;
  uStack_148 = 0;
  uStack_150 = 0;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgENS_4fposI11__mbstate_tEE
            (param_3,&uStack_160);
  uVar6 = 0x15;
  if ((uStack_50 < 0x100) || (*(int *)((long)param_3 + *(long *)(*param_3 + -0x18) + 0x20) != 0))
  goto LAB_01529368;
  puVar5 = (undefined8 *)__Znwm(0x100);
  puVar5[0x1d] = 0;
  puVar5[0x1c] = 0;
  puVar5[0x1f] = 0;
  puVar5[0x1e] = 0;
  puVar5[0x19] = 0;
  puVar5[0x18] = 0;
  puVar5[0x1b] = 0;
  puVar5[0x1a] = 0;
  puVar5[0x15] = 0;
  puVar5[0x14] = 0;
  puVar5[0x17] = 0;
  puVar5[0x16] = 0;
  puVar5[0x11] = 0;
  puVar5[0x10] = 0;
  puVar5[0x13] = 0;
  puVar5[0x12] = 0;
  puVar5[0xd] = 0;
  puVar5[0xc] = 0;
  puVar5[0xf] = 0;
  puVar5[0xe] = 0;
  puVar5[9] = 0;
  puVar5[8] = 0;
  puVar5[0xb] = 0;
  puVar5[10] = 0;
  puVar5[5] = 0;
  puVar5[4] = 0;
  puVar5[7] = 0;
  puVar5[6] = 0;
  puVar5[1] = 0;
  *puVar5 = 0;
  puVar5[3] = 0;
  puVar5[2] = 0;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(param_3,puVar5,0x100);
  if (*(int *)((long)param_3 + *(long *)(*param_3 + -0x18) + 0x20) == 0) {
    lVar3 = func_0x00f5b2a4(0);
    iVar2 = func_0x00f5bb20(lVar3,0x4000);
    if (iVar2 == 0) {
      iVar2 = func_0x00f5bb9c(lVar3,puVar5,0x100);
      if (iVar2 != 0) {
        pcVar4 = "JxlDecoderSetInput failed";
        goto LAB_01529474;
      }
      auStack_d0[0] = 0;
      pcVar4 = "Error, failed to get box type";
      do {
        iVar2 = func_0x00f5bbf0(lVar3);
        if (iVar2 != 0x4000) {
          pcVar4 = "Unknown decoder status";
          if (iVar2 == 1) {
            pcVar4 = "Decoder error in LoadGlobalVersion";
          }
          pcVar1 = "Error, already provided all input";
          if (iVar2 != 2) {
            pcVar1 = pcVar4;
          }
          func_0x00574408(pcVar1);
          goto LAB_01529534;
        }
        iVar2 = func_0x00f5ffa8(lVar3,&iStack_164,0);
        if (iVar2 != 0) goto LAB_015294fc;
      } while (iStack_164 != 0x76703143);
      iVar2 = func_0x00f5ffdc(lVar3,auStack_d0);
      if (iVar2 == 0) {
        func_0x00f9db28(&pbStack_180,auStack_d0[0]);
        func_0x00f5ff04(lVar3,pbStack_180,(long)pbStack_178 - (long)pbStack_180);
        func_0x00f5bbf0(lVar3);
        uVar6 = 0;
        *param_2 = (uint)*pbStack_180;
      }
      else {
        pcVar4 = "JxlDecoderGetBoxSizeRaw failed";
LAB_015294fc:
        func_0x00574408(pcVar4);
LAB_01529534:
        uVar6 = 0x15;
      }
    }
    else {
      pcVar4 = "JxlDecoderSubscribeEvents failed";
LAB_01529474:
      func_0x00574408(pcVar4);
    }
    if (lVar3 != 0) {
      func_0x00f5b548(lVar3);
    }
  }
  __ZdlPv(puVar5);
  if (pbStack_180 != (byte *)0x0) {
    pbStack_178 = pbStack_180;
    __ZdlPv();
  }
LAB_01529368:
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_48) {
    return uVar6;
  }
  ___stack_chk_fail();
  iVar2 = extraout_w1;
  while (iVar2 != 0) {
    func_0x000e3a54();
    iVar2 = extraout_w1_00;
  }
  __Unwind_Resume();
  puVar5 = (undefined8 *)__Znwm(0xc);
  *(undefined4 *)(puVar5 + 1) = 0;
  *puVar5 = 0;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(extraout_x1,puVar5,0xc);
  if (*(int *)((long)extraout_x1 + *(long *)(*extraout_x1 + -0x18) + 0x20) != 0) {
    __ZdlPv(puVar5);
    return false;
  }
  iVar2 = func_0x00f5ad4c(puVar5,0xc);
  __ZdlPv(puVar5);
  return iVar2 == 3;
}


/* __ZNK5Proxy7JPEG_XL10QuickCheckERNSt3__114basic_ifstreamIcNS1_11char_traitsIcEEEE @ 01529590 */

bool __ZNK5Proxy7JPEG_XL10QuickCheckERNSt3__114basic_ifstreamIcNS1_11char_traitsIcEEEE
               (undefined8 param_1,long *param_2)

{
  int iVar1;
  undefined8 *puVar2;

  puVar2 = (undefined8 *)__Znwm(0xc);
  *(undefined4 *)(puVar2 + 1) = 0;
  *puVar2 = 0;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(param_2,puVar2,0xc);
  if (*(int *)((long)param_2 + *(long *)(*param_2 + -0x18) + 0x20) != 0) {
    __ZdlPv(puVar2);
    return false;
  }
  iVar1 = func_0x00f5ad4c(puVar2,0xc);
  __ZdlPv(puVar2);
  return iVar1 == 3;
}


/* __ZNK5Proxy7JPEG_XL12LoadMetadataERNS_15BackendLoadInfoEjRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEE @ 01529628 */

/* WARNING: Possible PIC construction at 0x0152992c: Changing call to branch */
/* WARNING: Possible PIC construction at 0x01529908: Changing call to branch */
/* WARNING: Possible PIC construction at 0x015299c8: Changing call to branch */
/* WARNING: Removing unreachable block (ram,0x0152990c) */
/* WARNING: Removing unreachable block (ram,0x0152991c) */
/* WARNING: Removing unreachable block (ram,0x015299fc) */
/* WARNING: Removing unreachable block (ram,0x01529930) */
/* WARNING: Removing unreachable block (ram,0x01529944) */
/* WARNING: Removing unreachable block (ram,0x015299a8) */
/* WARNING: Removing unreachable block (ram,0x01529958) */
/* WARNING: Removing unreachable block (ram,0x01529964) */
/* WARNING: Removing unreachable block (ram,0x01529978) */
/* WARNING: Removing unreachable block (ram,0x01529988) */
/* WARNING: Removing unreachable block (ram,0x0152998c) */
/* WARNING: Removing unreachable block (ram,0x01529998) */
/* WARNING: Removing unreachable block (ram,0x0152999c) */
/* WARNING: Removing unreachable block (ram,0x015299cc) */
/* WARNING: Removing unreachable block (ram,0x015299d4) */
/* WARNING: Removing unreachable block (ram,0x015299ec) */

long ** __ZNK5Proxy7JPEG_XL12LoadMetadataERNS_15BackendLoadInfoEjRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEE
                  (undefined8 param_1,undefined8 *param_2,undefined8 param_3,long *param_4)

{
  long lVar1;
  int iVar2;
  long lVar3;
  char *pcVar4;
  long **pplVar5;
  long **pplVar6;
  int extraout_w1;
  int extraout_w1_00;
  long *plStack_210;
  undefined8 *puStack_208;
  undefined1 *puStack_200;
  undefined8 *puStack_1f8;
  long *plStack_1f0;
  undefined8 *puStack_1e8;
  undefined8 *puStack_1e0;
  undefined1 *puStack_1d8;
  undefined8 uStack_1d0;
  undefined1 uStack_1c1;
  long alStack_1c0 [2];
  undefined1 auStack_1b0 [4];
  undefined8 uStack_1ac;
  ulong uStack_130;
  undefined8 uStack_e0;
  undefined8 uStack_d8;
  undefined8 uStack_d0;
  undefined8 uStack_c8;
  undefined8 uStack_c0;
  undefined8 uStack_b8;
  undefined8 uStack_b0;
  undefined8 uStack_a8;
  undefined8 uStack_a0;
  undefined8 uStack_98;
  undefined8 uStack_90;
  undefined8 uStack_88;
  undefined8 uStack_80;
  undefined8 uStack_78;
  undefined8 uStack_70;
  undefined8 uStack_68;
  undefined8 uStack_60;
  long lStack_58;

  lStack_58 = *(long *)PTR____stack_chk_guard_01d15188;
  *(undefined1 *)(param_2 + 4) = 1;
  if (((*(int *)((long)param_4 + *(long *)(*param_4 + -0x18) + 0x20) != 0) ||
      (__ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgExNS_8ios_base7seekdirE(param_4,0,2),
      *(int *)((long)param_4 + *(long *)(*param_4 + -0x18) + 0x20) != 0)) ||
     (__ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5tellgEv(auStack_1b0,param_4),
     0x7ffffffffffffffe < uStack_130)) goto LAB_015296f8;
  uStack_60 = 0;
  uStack_78 = 0;
  uStack_80 = 0;
  uStack_68 = 0;
  uStack_70 = 0;
  uStack_98 = 0;
  uStack_a0 = 0;
  uStack_88 = 0;
  uStack_90 = 0;
  uStack_b8 = 0;
  uStack_c0 = 0;
  uStack_a8 = 0;
  uStack_b0 = 0;
  uStack_d8 = 0;
  uStack_e0 = 0;
  uStack_c8 = 0;
  uStack_d0 = 0;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgENS_4fposI11__mbstate_tEE
            (param_4,&uStack_e0);
  if (*(int *)((long)param_4 + *(long *)(*param_4 + -0x18) + 0x20) != 0) goto LAB_015296f8;
  if (uStack_130 == 0) {
    lVar3 = 0;
  }
  else {
    lVar3 = __Znwm(uStack_130);
    _bzero(lVar3,uStack_130);
  }
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(param_4,lVar3,uStack_130);
  if (*(int *)((long)param_4 + *(long *)(*param_4 + -0x18) + 0x20) != 0) goto LAB_015297d4;
  alStack_1c0[0] = func_0x00f5b2a4(0);
  iVar2 = func_0x00f5bb20(alStack_1c0[0],0x40);
  if (iVar2 != 0) {
    pcVar4 = "JxlDecoderSubscribeEvents failed";
LAB_015297bc:
    func_0x00574408(pcVar4);
    goto LAB_015297c0;
  }
  iVar2 = func_0x00f5bb9c(alStack_1c0[0],lVar3,uStack_130);
  if (iVar2 != 0) {
    pcVar4 = "JxlDecoderSetInput failed";
    goto LAB_015297bc;
  }
  func_0x00f5bbe4(alStack_1c0[0]);
  func_0x00f5bbf0(alStack_1c0[0]);
  iVar2 = func_0x00f5f3c4(alStack_1c0[0],auStack_1b0);
  if (iVar2 != 0) {
    pcVar4 = "JxlDecoderGetBasicInfo failed";
LAB_01529884:
    func_0x00574408(pcVar4);
    goto LAB_015297c0;
  }
  *param_2 = uStack_1ac;
  func_0x00f5bbd0(alStack_1c0[0]);
  func_0x00f5b238(alStack_1c0[0]);
  iVar2 = func_0x00f5bb20(alStack_1c0[0],0x4000);
  if (iVar2 != 0) {
    pcVar4 = "JxlDecoderSubscribeEvents failed";
    goto LAB_01529884;
  }
  iVar2 = func_0x00f5bb9c(alStack_1c0[0],lVar3,uStack_130);
  if (iVar2 != 0) {
    pcVar4 = "JxlDecoderSetInput failed";
    goto LAB_01529884;
  }
  func_0x00f5bbe4(alStack_1c0[0]);
  iVar2 = func_0x00f5ff94(alStack_1c0[0],1);
  if (iVar2 != 0) {
    pcVar4 = "JxlDecoderSetDecompressBoxes failed";
    goto LAB_01529884;
  }
  puStack_1f8 = param_2 + 1;
  param_2[2] = *puStack_1f8;
  uStack_1c1 = 0;
  plStack_210 = alStack_1c0;
  puStack_208 = &uStack_1d0;
  puStack_200 = &uStack_1c1;
  uStack_1d0 = 0;
  pcVar4 = "Decoder error in LoadMetadata";
  plStack_1f0 = plStack_210;
  puStack_1e8 = puStack_1f8;
  puStack_1e0 = puStack_208;
  puStack_1d8 = puStack_200;
  iVar2 = func_0x00f5bbf0(alStack_1c0[0]);
  switch(iVar2) {
  case 0:
    pplVar5 = &plStack_210;
    goto
    __ZZNK5Proxy7JPEG_XL12LoadMetadataERNS_15BackendLoadInfoEjRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEEENK3__1clEv
    ;
  case 1:
    break;
  case 2:
    pcVar4 = "Error, already provided all input";
    break;
  case 7:
    pplVar5 = &plStack_210;
    goto
    __ZZNK5Proxy7JPEG_XL12LoadMetadataERNS_15BackendLoadInfoEjRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEEENK3__1clEv
    ;
  default:
    if (iVar2 == 0x4000) {
      pplVar5 = &plStack_210;
      goto
      __ZZNK5Proxy7JPEG_XL12LoadMetadataERNS_15BackendLoadInfoEjRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEEENK3__1clEv
      ;
    }
  case 3:
  case 4:
  case 5:
  case 6:
    pcVar4 = "Unknown decoder status";
  }
  func_0x00574408(pcVar4);
LAB_015297c0:
  lVar1 = alStack_1c0[0];
  alStack_1c0[0] = 0;
  if (lVar1 != 0) {
    func_0x00f5b548();
  }
LAB_015297d4:
  if (lVar3 != 0) {
    __ZdlPv(lVar3);
  }
LAB_015296f8:
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_58) {
    return (long **)((long)&MACH_HEADER.sizeofcmds + 1);
  }
  ___stack_chk_fail();
  iVar2 = extraout_w1;
  while (iVar2 != 0) {
    func_0x000e3a54();
    iVar2 = extraout_w1_00;
  }
  pplVar5 = (long **)__Unwind_Resume();

  __ZZNK5Proxy7JPEG_XL12LoadMetadataERNS_15BackendLoadInfoEjRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEEENK3__1clEv
  :
  pplVar6 = pplVar5;
  if ((char)*pplVar5[2] != '\0') {
    *(char *)pplVar5[2] = '\0';
    pplVar6 = (long **)func_0x00f5ff40(**pplVar5);
    *pplVar5[1] = (pplVar5[3][1] - *pplVar5[3]) - (long)pplVar6;
  }
  return pplVar6;
}


/* __ZZNK5Proxy7JPEG_XL12LoadMetadataERNS_15BackendLoadInfoEjRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEEENK3$_1clEv @ 01529a28 */

void __ZZNK5Proxy7JPEG_XL12LoadMetadataERNS_15BackendLoadInfoEjRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEEENK3__1clEv
               (undefined8 *param_1)

{
  long lVar1;

  if (*(char *)param_1[2] != '\0') {
    *(char *)param_1[2] = '\0';
    lVar1 = func_0x00f5ff40(*(undefined8 *)*param_1);
    *(long *)param_1[1] = (((long *)param_1[3])[1] - *(long *)param_1[3]) - lVar1;
  }
  return;
}


/* __ZZNK5Proxy7JPEG_XL12LoadMetadataERNS_15BackendLoadInfoEjRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEEENK3$_0clEm @ 01529a78 */

/* WARNING: Possible PIC construction at 0x0152b028: Changing call to branch */
/* WARNING: Removing unreachable block (ram,0x0152b02c) */
/* WARNING: Removing unreachable block (ram,0x0152b038) */
/* WARNING: Removing unreachable block (ram,0x0152b040) */
/* WARNING: Removing unreachable block (ram,0x0152b06c) */
/* WARNING: Removing unreachable block (ram,0x0152b058) */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8
__ZZNK5Proxy7JPEG_XL12LoadMetadataERNS_15BackendLoadInfoEjRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEEENK3__0clEm
          (undefined8 *param_1,ulong param_2,long param_3)

{
  int iVar1;
  uint uVar2;
  undefined4 uVar3;
  uint uVar4;
  code *pcVar5;
  bool bVar6;
  int iVar7;
  uint uVar9;
  int iVar8;
  undefined1 *puVar10;
  long lVar11;
  undefined8 uVar12;
  undefined8 uVar13;
  undefined8 uVar14;
  long *plVar15;
  char *pcVar16;
  long *extraout_x1;
  undefined8 extraout_x1_00;
  long *plVar17;
  int iVar18;
  ulong uVar19;
  ulong uVar20;
  long lVar21;
  undefined8 *puVar22;
  ulong uVar23;
  undefined8 *puVar24;
  undefined8 *puVar25;
  undefined8 *puVar26;
  undefined8 *puVar27;
  int iVar28;
  ulong uVar29;
  undefined8 *puVar30;
  long lVar31;
  undefined8 *puVar32;
  undefined8 *puVar33;
  long lVar34;
  long lVar35;
  undefined8 *puVar36;
  long *plVar37;
  undefined1 *puVar38;
  undefined1 *puVar39;
  uint uVar40;
  undefined8 *puVar41;
  undefined4 uVar42;
  undefined8 *puVar43;
  undefined4 uVar44;
  undefined4 uVar45;
  undefined8 *puVar46;
  ulong uVar47;
  float fVar48;
  undefined8 uVar49;
  undefined8 uVar50;
  undefined8 uVar51;
  undefined8 uVar52;
  undefined8 uVar53;
  undefined8 uVar54;
  undefined1 auVar55 [12];
  undefined1 auVar56 [16];
  char *pcStack_798;
  char *pcStack_790;
  char *pcStack_780;
  undefined8 auStack_778 [2];
  char cStack_761;
  long lStack_760;
  long lStack_758;
  undefined8 uStack_750;
  long lStack_748;
  int iStack_740;
  undefined4 uStack_72c;
  undefined4 uStack_728;
  undefined8 uStack_710;
  undefined8 uStack_708;
  undefined8 uStack_700;
  long lStack_6f0;
  long lStack_6e8;
  undefined8 uStack_6e0;
  undefined1 auStack_6d8 [184];
  undefined1 auStack_620 [128];
  ulong uStack_5a0;
  undefined8 uStack_550;
  undefined8 uStack_548;
  undefined8 uStack_540;
  undefined8 uStack_538;
  undefined8 uStack_530;
  undefined8 uStack_528;
  undefined8 uStack_520;
  undefined8 uStack_518;
  undefined8 uStack_510;
  undefined8 uStack_508;
  undefined8 uStack_500;
  undefined8 uStack_4f8;
  undefined8 uStack_4f0;
  undefined8 uStack_4e8;
  undefined8 uStack_4e0;
  undefined8 uStack_4d8;
  undefined8 uStack_4d0;
  long lStack_4c8;
  ulong uStack_4b0;
  undefined8 *puStack_4a8;
  ulong uStack_4a0;
  undefined8 *puStack_498;
  undefined8 *puStack_490;
  undefined8 uStack_488;
  long *plStack_480;
  undefined8 *puStack_478;
  undefined8 uStack_470;
  long lStack_468;
  undefined1 ***pppuStack_460;
  undefined8 uStack_458;
  undefined4 uStack_450;
  undefined2 uStack_44c;
  undefined1 uStack_439;
  undefined8 uStack_438;
  undefined8 uStack_430;
  long lStack_428;
  undefined1 **ppuStack_420;
  undefined8 uStack_418;
  undefined8 uStack_410;
  long *plStack_408;
  long lStack_400;
  undefined8 *puStack_3f8;
  undefined8 *puStack_3f0;
  undefined8 *puStack_3e8;
  undefined8 *puStack_3e0;
  undefined4 auStack_3d8 [4];
  undefined4 uStack_3c8;
  undefined8 uStack_3a0;
  undefined8 uStack_398;
  undefined8 uStack_390;
  long lStack_388;
  undefined8 uStack_380;
  undefined8 uStack_378;
  undefined8 uStack_370;
  undefined8 uStack_368;
  undefined8 uStack_360;
  undefined8 uStack_358;
  undefined8 uStack_350;
  undefined8 uStack_348;
  undefined8 uStack_340;
  undefined8 uStack_338;
  undefined8 uStack_330;
  undefined8 uStack_328;
  undefined8 uStack_320;
  int aiStack_314 [3];
  undefined8 uStack_308;
  undefined4 uStack_300;
  undefined4 uStack_2f0;
  undefined4 uStack_2e8;
  undefined8 uStack_2c4;
  undefined8 uStack_2bc;
  undefined1 auStack_248 [24];
  int iStack_230;
  int iStack_22c;
  int iStack_228;
  uint uStack_224;
  undefined4 uStack_220;
  long lStack_210;
  long lStack_208;
  undefined1 auStack_190 [24];
  int iStack_178;
  int iStack_174;
  int iStack_170;
  int iStack_16c;
  int iStack_168;
  long lStack_158;
  long lStack_150;
  long lStack_d8;
  ulong uStack_c0;
  undefined8 *puStack_b8;
  undefined1 *puStack_70;
  undefined8 uStack_68;

  if (param_2 == 0) {
    plVar37 = (long *)param_1[1];
    param_2 = *(long *)param_1[2] + 0x8000;
    puVar46 = (undefined8 *)*plVar37;
    puVar33 = (undefined8 *)plVar37[1];
    uVar47 = (long)puVar33 - (long)puVar46;
    bVar6 = uVar47 <= param_2;
    puVar41 = (undefined8 *)(param_2 - uVar47);
    if (!bVar6 || puVar41 == (undefined8 *)0x0) goto LAB_01529b5c;
  }
  else {
    plVar37 = (long *)param_1[1];
    puVar46 = (undefined8 *)*plVar37;
    puVar33 = (undefined8 *)plVar37[1];
    uVar47 = (long)puVar33 - (long)puVar46;
    bVar6 = uVar47 <= param_2;
    puVar41 = (undefined8 *)(param_2 - uVar47);
    if (!bVar6 || puVar41 == (undefined8 *)0x0) {
LAB_01529b5c:
      if (!bVar6) {
        plVar37[1] = (long)puVar46 + param_2;
      }
      goto _JxlDecoderSetBoxBuffer;
    }
  }
  if (puVar41 <= (undefined8 *)(plVar37[2] - (long)puVar33)) {
    _bzero(puVar33,puVar41);
    plVar37[1] = (long)puVar33 + (long)puVar41;
    goto _JxlDecoderSetBoxBuffer;
  }
  if (-1 < (long)param_2) {
    uVar19 = plVar37[2] - (long)puVar46;
    uVar29 = uVar19 * 2;
    if (uVar29 < param_2 || uVar29 - param_2 == 0) {
      uVar29 = param_2;
    }
    if (0x3ffffffffffffffe < uVar19) {
      uVar29 = 0x7fffffffffffffff;
    }
    puVar10 = (undefined1 *)__Znwm(uVar29);
    puVar38 = puVar10 + uVar47;
    _bzero(puVar38,puVar41);
    puVar41 = puVar33;
    puVar39 = puVar38;
    if (puVar33 != puVar46) {
      puVar30 = puVar33;
      puVar41 = puVar46;
      puVar39 = puVar10;
      if ((7 < uVar47) && (0x3f < (ulong)((long)puVar46 - (long)puVar10))) {
        if (uVar47 < 0x40) {
          uVar20 = 0;
        }
        else {
          uVar20 = uVar47 & 0xffffffffffffffc0;
          puVar24 = puVar33 + -4;
          puVar30 = (undefined8 *)(puVar10 + ((long)puVar24 - (long)puVar46));
          uVar19 = uVar20;
          do {
            uVar14 = *puVar24;
            uVar13 = puVar24[3];
            uVar12 = puVar24[2];
            uVar52 = puVar24[-3];
            uVar51 = puVar24[-4];
            uVar50 = puVar24[-1];
            uVar49 = puVar24[-2];
            puVar30[1] = puVar24[1];
            *puVar30 = uVar14;
            puVar30[3] = uVar13;
            puVar30[2] = uVar12;
            puVar30[-3] = uVar52;
            puVar30[-4] = uVar51;
            puVar30[-1] = uVar50;
            puVar30[-2] = uVar49;
            puVar30 = puVar30 + -8;
            puVar24 = puVar24 + -8;
            uVar19 = uVar19 - 0x40;
          } while (uVar19 != 0);
          if (uVar47 == uVar20) goto LAB_01529c2c;
          if ((uVar47 & 0x38) == 0) {
            puVar38 = puVar38 + -uVar20;
            puVar30 = (undefined8 *)((long)puVar33 - uVar20);
            goto LAB_01529c14;
          }
        }
        uVar19 = uVar47 & 0xfffffffffffffff8;
        puVar30 = (undefined8 *)((long)puVar33 - uVar19);
        puVar38 = puVar38 + -uVar19;
        puVar33 = (undefined8 *)((long)puVar33 + (-8 - uVar20));
        lVar35 = (long)puVar33 - (long)puVar46;
        lVar21 = uVar20 - uVar19;
        do {
          *(undefined8 *)(puVar10 + lVar35) = *puVar33;
          lVar35 = lVar35 + -8;
          lVar21 = lVar21 + 8;
          puVar33 = puVar33 + -1;
        } while (lVar21 != 0);
        if (uVar47 == uVar19) goto LAB_01529c2c;
      }
LAB_01529c14:
      do {
        puVar38 = puVar38 + -1;
        puVar30 = (undefined8 *)((long)puVar30 + -1);
        *puVar38 = *(undefined1 *)puVar30;
      } while (puVar30 != puVar46);
    }
LAB_01529c2c:
    *plVar37 = (long)puVar39;
    plVar37[1] = (long)(puVar10 + param_2);
    plVar37[2] = (long)(puVar10 + uVar29);
    if (puVar41 != (undefined8 *)0x0) {
      __ZdlPv(puVar41);
    }
_JxlDecoderSetBoxBuffer:
    plVar37 = (long *)param_1[2];
    *(undefined1 *)param_1[3] = 1;
    lVar11 = *(long *)*param_1;
    lVar35 = ((long *)param_1[1])[1];
    lVar21 = *(long *)param_1[1] + *plVar37;
    if ((*(char *)(lVar11 + 0x3c3) == '\0') && (*(char *)(lVar11 + 0x3c1) != '\0')) {
      *(undefined2 *)(lVar11 + 0x3c3) = 0x101;
      *(long *)(lVar11 + 0x3c8) = lVar21;
      *(long *)(lVar11 + 0x3d0) = lVar35 - lVar21;
      *(undefined8 *)(lVar11 + 0x3e0) = 0;
      return 0;
    }
    return 1;
  }
  func_0x00108ee8(plVar37);
  uStack_68 = 0x1529c88;
  lStack_d8 = *(long *)PTR____stack_chk_guard_01d15188;
  lVar35 = *(long *)(param_3 + 0x20);
  uStack_c0 = uVar47;
  puStack_b8 = puVar46;
  puStack_70 = &stack0xfffffffffffffff0;
  func_0x011947c8(auStack_190);
  lVar21 = *(long *)(lVar35 + 0x40);
  if (lVar21 == 0) {
    lVar11 = 0;
    lVar21 = 0;
  }
  else {
    iVar7 = *(int *)(lVar35 + 0x20);
    iVar8 = *(int *)(lVar35 + 0x24);
    iVar18 = *(int *)(lVar35 + 0x18);
    iVar1 = *(int *)(lVar35 + 0x1c);
    iVar28 = 0xc;
    switch(*(undefined4 *)(lVar35 + 0x28)) {
    case 1:
    case 0xd:
      iVar28 = 2;
      break;
    default:
      func_0x015254fc(*(undefined4 *)(lVar35 + 0x28),0,aiStack_314,auStack_248);
      lVar31 = *(long *)(lVar35 + 0x38);
      lVar21 = *(long *)(lVar35 + 0x40);
      lVar11 = lVar21 + lVar31 * iVar1 + (long)aiStack_314[0] * (long)iVar18;
      if (lVar21 == 0) {
        lVar21 = 0;
        goto LAB_01529de4;
      }
      goto LAB_01529d6c;
    case 3:
      iVar28 = 6;
      break;
    case 4:
      break;
    case 0xe:
      iVar28 = 4;
    }
    lVar31 = *(long *)(lVar35 + 0x38);
    lVar11 = lVar21 + lVar31 * iVar1 + (long)iVar28 * (long)iVar18;
LAB_01529d6c:
    iVar18 = *(int *)(lVar35 + 0x18);
    puVar41 = (undefined8 *)(long)*(int *)(lVar35 + 0x1c);
    lVar34 = 0xc;
    switch(*(undefined4 *)(lVar35 + 0x28)) {
    case 1:
    case 0xd:
      lVar34 = 2;
      break;
    default:
      func_0x015254fc(*(undefined4 *)(lVar35 + 0x28),0,aiStack_314,auStack_248);
      lVar34 = (long)aiStack_314[0];
      lVar31 = *(long *)(lVar35 + 0x38);
      lVar21 = *(long *)(lVar35 + 0x40);
      break;
    case 3:
      lVar34 = 6;
      break;
    case 4:
      break;
    case 0xe:
      lVar34 = 4;
    }
    lVar21 = lVar21 + lVar34 * ((long)iVar18 + (long)iVar7) +
                      lVar31 * ((long)puVar41 + (long)(iVar8 + -1));
  }
LAB_01529de4:
  iVar7 = *(int *)(lVar35 + 0x20);
  iVar8 = *(int *)(lVar35 + 0x24);
  puVar33 = (undefined8 *)(long)iVar8;
  iVar18 = 0xc;
  switch(*(undefined4 *)(lVar35 + 0x28)) {
  case 1:
    if (lVar21 - lVar11 == (long)iVar8 * (long)iVar7 * 2) break;
    goto LAB_01529e80;
  default:
    func_0x015254fc(*(undefined4 *)(lVar35 + 0x28),0,aiStack_314,auStack_248);
    if (lVar21 - lVar11 != (long)iVar8 * (long)iVar7 * (long)aiStack_314[0]) goto LAB_01529e80;
    break;
  case 3:
    if (lVar21 - lVar11 != (long)iVar8 * (long)iVar7 * 6) goto LAB_01529e80;
    break;
  case 4:
    goto code_r0x01529ee0;
  case 0xd:
    iVar18 = 2;
code_r0x01529ee0:
    if (lVar21 - lVar11 == (long)iVar8 * (long)iVar7 * (long)iVar18) break;
LAB_01529e80:
    func_0x01195d64(auStack_190,*(undefined4 *)(lVar35 + 0x20),*(undefined4 *)(lVar35 + 0x24),0,
                    *(undefined4 *)(lVar35 + 0x28),0);
    uVar47 = func_0x01197c24(auStack_190,lVar35);
    if ((uVar47 & 1) == 0) {
      uVar12 = ___cxa_allocate_exception(0x10);
      __ZNSt13runtime_errorC1EPKc(uVar12,"MakeDense: failed to copy buffer");
      ___cxa_throw(uVar12,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18
                  );
      goto LAB_0152ad58;
    }
    goto LAB_01529f10;
  case 0xe:
    if (lVar21 - lVar11 != (long)iVar8 * (long)iVar7 * 4) goto LAB_01529e80;
  }
  func_0x01197340(auStack_190,lVar35,0,0,0);
LAB_01529f10:
  if (iStack_168 != 3) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"Saving proxy: unsupported image format.");
    ___cxa_throw(uVar12,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  func_0x011947c8(auStack_248);
  iVar7 = iStack_170;
  if (iStack_170 <= iStack_16c) {
    iVar7 = iStack_16c;
  }
  fVar48 = (float)NEON_fminnm(450.0 / (float)iVar7,0x3f800000);
  uVar12 = 0;
  func_0x01195d64(auStack_248,(int)(fVar48 * (float)iStack_170),(int)(fVar48 * (float)iStack_16c),0,
                  3,0);
  func_0x014bd6f4(auStack_190,auStack_248,&__ZN4ICPP19ResizeSuper_16u_C3REPK12CImageBufferPS0_dddd);
  lVar21 = func_0x00f178e4(0);
  lStack_388 = lVar21;
  iVar7 = func_0x00f18588(lVar21,&__Z21ImgCoreParallelRunnerPvS_PFiS_mEPFvS_jmEjj,0);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderSetParallelRunner failed");
    ___cxa_throw(uVar12,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  iVar7 = func_0x00f1862c(lVar21);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderUseBoxes failed");
LAB_0152aa98:
    ___cxa_throw(uVar12,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  iVar7 = func_0x00f18658(lVar21,&__ZN5ProxyL14JXLBOX_VERSIONE,param_3 + 4,4,0);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderAddBox failed: version");
    goto LAB_0152aa98;
  }
  iVar7 = func_0x00f18658(lVar21,&__ZN5ProxyL15JXLBOX_METADATAE,*(long *)(param_3 + 8),
                          *(long *)(param_3 + 0x10) - *(long *)(param_3 + 8),0);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderAddBox failed: metadata");
    goto LAB_0152aa98;
  }
  func_0x00f19838(lVar21);
  uStack_390 = 0;
  uStack_398 = _UNK_01a9bd70;
  uStack_3a0 = _UNK_01a9bd68;
  func_0x00f16bfc(aiStack_314);
  aiStack_314[0] = 1;
  uStack_308 = _UNK_01a9bec8;
  uStack_300 = 0x44fa0000;
  if (*(char *)(param_3 + 0x29) != '\0') {
    uStack_300 = 0x47435000;
  }
  uStack_2f0 = 0;
  uStack_2e8 = 1;
  uStack_2bc = _UNK_017d9748;
  uStack_2c4 = _UNK_017d9740;
  iVar7 = func_0x00f16c48(lVar21,aiStack_314);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderSetBasicInfo failed");
    ___cxa_throw(uVar12,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  uStack_320 = 0;
  uStack_338 = 0;
  uStack_340 = 0;
  uStack_328 = 0;
  uStack_330 = 0;
  uStack_358 = 0;
  uStack_360 = 0;
  uStack_348 = 0;
  uStack_350 = 0;
  uStack_378 = 0;
  uStack_380 = 0;
  uStack_368 = 0;
  uStack_370 = 0;
  func_0x00f1a0bc(&uStack_380,0);
  iVar7 = func_0x00f16b60(lVar21,&uStack_380);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderSetColorEncoding failed");
    ___cxa_throw(uVar12,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  uVar13 = func_0x00f171b4(lVar21,0);
  uVar14 = func_0x00f171b4(lVar21,0);
  iVar7 = func_0x00f17894(0x3f19999a,uVar13);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderSetFrameDistance failed: proxy");
    ___cxa_throw(uVar12,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  iVar7 = *(int *)(param_3 + 0x2c);
  if (iVar7 != 3) {
    if (iVar7 != 6) {
      func_0x00574348("GetEncodingEffort: Unknown");
    }
    iVar7 = 5;
  }
  iVar7 = func_0x00f174e8(uVar13,0,iVar7);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderFrameSettingsSetOption failed: proxy effort");
LAB_0152abf4:
    ___cxa_throw(uVar12,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  iVar7 = func_0x00f174e8(uVar13,10,0);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderFrameSettingsSetOption failed: proxy gaborish");
    goto LAB_0152abf4;
  }
  iVar7 = func_0x00f174e8(uVar13,0xb,0);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderFrameSettingsSetOption failed: proxy modular");
    goto LAB_0152abf4;
  }
  iVar7 = func_0x00f17894(0x3dcccccd,uVar14);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderSetFrameDistance failed: thumb");
    goto LAB_0152abf4;
  }
  iVar7 = func_0x00f174e8(uVar14,0,5);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderFrameSettingsSetOption failed: thumb effort");
    goto LAB_0152abf4;
  }
  iVar7 = func_0x00f174e8(uVar14,0xb,0);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderFrameSettingsSetOption failed: thumb modular");
    goto LAB_0152abf4;
  }
  func_0x00f16c30(auStack_3d8);
  auStack_3d8[0] = 1;
  uStack_3c8 = 1;
  iVar7 = func_0x00f19ecc(uVar14,auStack_3d8);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderSetFrameHeader failed: thumb");
LAB_0152ac44:
    ___cxa_throw(uVar12,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  iVar8 = func_0x00f19f68(uVar14,"thumb");
  iVar7 = iStack_230;
  if (iVar8 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderSetFrameName failed: thumb");
    goto LAB_0152ac44;
  }
  if (lStack_208 == 0) {
    lVar11 = 0;
    lVar35 = 0;
    lStack_208 = 0;
  }
  else {
    puVar33 = (undefined8 *)(ulong)uStack_224;
    puVar41 = (undefined8 *)(long)iStack_22c;
    iVar8 = 0xc;
    switch(uStack_220) {
    case 1:
    case 0xd:
      iVar8 = 2;
      break;
    default:
      func_0x015254fc(uStack_220,0,&puStack_3f0,&puStack_3f8);
      lVar35 = lStack_208 + lStack_210 * (long)puVar41 + (long)(int)puStack_3f0 * (long)iVar7;
      if (lStack_208 == 0) {
        lVar11 = 0;
        lStack_208 = 0;
        goto LAB_0152a3a8;
      }
      goto LAB_0152a29c;
    case 3:
      iVar8 = 6;
      break;
    case 4:
      break;
    case 0xe:
      iVar8 = 4;
    }
    lVar35 = lStack_208 + lStack_210 * (long)puVar41 + (long)iVar8 * (long)iStack_230;
LAB_0152a29c:
    lVar31 = (long)iStack_230;
    puVar33 = (undefined8 *)((long)iStack_22c + (long)(int)(uStack_224 - 1));
    lVar11 = 0xc;
    switch(uStack_220) {
    case 1:
    case 0xd:
      lVar11 = 2;
      break;
    default:
      func_0x015254fc(uStack_220,0,&puStack_3f0,&puStack_3f8);
      lVar11 = lStack_208 +
               lStack_210 * (int)puVar33 + (long)(int)puStack_3f0 * (long)(int)(lVar31 + iStack_228)
      ;
      if (lStack_208 == 0) {
        lStack_208 = 0;
        goto LAB_0152a3a8;
      }
      goto LAB_0152a334;
    case 3:
      lVar11 = 6;
      break;
    case 4:
      break;
    case 0xe:
      lVar11 = 4;
    }
    lVar11 = lStack_208 + lVar11 * (lVar31 + iStack_228) + lStack_210 * (long)puVar33;
LAB_0152a334:
    puVar33 = (undefined8 *)(long)iStack_230;
    puVar41 = (undefined8 *)(long)iStack_22c;
    iVar7 = 0xc;
    switch(uStack_220) {
    case 1:
    case 0xd:
      iVar7 = 2;
      break;
    default:
      func_0x015254fc(uStack_220,0,&puStack_3f0,&puStack_3f8);
      iVar7 = (int)puStack_3f0;
      break;
    case 3:
      iVar7 = 6;
      break;
    case 4:
      break;
    case 0xe:
      iVar7 = 4;
    }
    lStack_208 = lStack_208 + lStack_210 * (long)puVar41 + (long)iVar7 * (long)iStack_230;
  }
LAB_0152a3a8:
  iVar7 = func_0x00f18e3c(uVar14,&uStack_3a0,lStack_208,lVar11 - lVar35);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderAddImageFrame failed: thumb");
LAB_0152acb0:
    ___cxa_throw(uVar12,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  uStack_3c8 = 0;
  iVar7 = func_0x00f19ecc(uVar13,auStack_3d8);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderSetFrameHeader failed: proxy");
    goto LAB_0152acb0;
  }
  iVar8 = func_0x00f19f68(uVar13,"proxy");
  iVar7 = iStack_178;
  if (iVar8 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderSetFrameName failed: proxy");
    goto LAB_0152acb0;
  }
  if (lStack_150 == 0) {
    lVar11 = 0;
    lVar35 = 0;
    lStack_150 = 0;
  }
  else {
    puVar33 = (undefined8 *)(long)iStack_174;
    iVar8 = 0xc;
    switch(iStack_168) {
    case 1:
    case 0xd:
      iVar8 = 2;
      break;
    default:
      func_0x015254fc(iStack_168,0,&puStack_3f0,&puStack_3f8);
      lVar35 = lStack_150 + lStack_158 * (long)puVar33 + (long)(int)puStack_3f0 * (long)iVar7;
      if (lStack_150 == 0) {
        lVar11 = 0;
        lStack_150 = 0;
        goto LAB_0152a5a8;
      }
      goto LAB_0152a49c;
    case 3:
      iVar8 = 6;
      break;
    case 4:
      break;
    case 0xe:
      iVar8 = 4;
    }
    lVar35 = lStack_150 + lStack_158 * (long)puVar33 + (long)iVar8 * (long)iStack_178;
LAB_0152a49c:
    lVar34 = (long)iStack_178;
    lVar11 = (long)iStack_174 + (long)(iStack_16c + -1);
    lVar31 = 0xc;
    switch(iStack_168) {
    case 1:
    case 0xd:
      lVar31 = 2;
      break;
    default:
      func_0x015254fc(iStack_168,0,&puStack_3f0,&puStack_3f8);
      lVar11 = lStack_150 +
               lStack_158 * (int)lVar11 + (long)(int)puStack_3f0 * (long)(int)(lVar34 + iStack_170);
      if (lStack_150 == 0) {
        lStack_150 = 0;
        goto LAB_0152a5a8;
      }
      goto LAB_0152a534;
    case 3:
      lVar31 = 6;
      break;
    case 4:
      break;
    case 0xe:
      lVar31 = 4;
    }
    lVar11 = lStack_150 + lVar31 * (lVar34 + iStack_170) + lStack_158 * lVar11;
LAB_0152a534:
    puVar33 = (undefined8 *)(long)iStack_174;
    iVar7 = 0xc;
    switch(iStack_168) {
    case 1:
    case 0xd:
      iVar7 = 2;
      break;
    default:
      func_0x015254fc(iStack_168,0,&puStack_3f0,&puStack_3f8);
      iVar7 = (int)puStack_3f0;
      break;
    case 3:
      iVar7 = 6;
      break;
    case 4:
      break;
    case 0xe:
      iVar7 = 4;
    }
    lStack_150 = lStack_150 + lStack_158 * (long)puVar33 + (long)iVar7 * (long)iStack_178;
  }
LAB_0152a5a8:
  iVar7 = func_0x00f18e3c(uVar13,&uStack_3a0,lStack_150,lVar11 - lVar35);
  if (iVar7 != 0) {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderAddImageFrame failed: proxy");
    ___cxa_throw(uVar12,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  func_0x00f19844(lVar21);
  plStack_408 = extraout_x1;
  puStack_3f8 = (undefined8 *)__Znwm(0x40);
  puStack_3f8[5] = 0;
  puStack_3f8[4] = 0;
  puStack_3f8[7] = 0;
  puStack_3f8[6] = 0;
  puStack_3f8[1] = 0;
  *puStack_3f8 = 0;
  puStack_3f8[3] = 0;
  puStack_3f8[2] = 0;
  puStack_3e8 = puStack_3f8 + 8;
  lStack_400 = 0x40;
  puStack_3f0 = puStack_3f8;
  puStack_3e0 = puStack_3e8;
  while( true ) {
    uVar13 = func_0x00f19850(lVar21,&puStack_3f8,&lStack_400);
    puVar36 = puStack_3e8;
    puVar24 = puStack_3f0;
    puVar30 = puStack_3f8;
    if ((int)uVar13 != 2) break;
    puVar41 = (undefined8 *)((long)puStack_3e8 - (long)puStack_3f0);
    puVar46 = (undefined8 *)((long)puVar41 * 2);
    if ((long)puVar41 < 1) {
      if ((long)puVar41 < 0) {
        puStack_3e8 = (undefined8 *)((long)puStack_3f0 + (long)puVar46);
      }
    }
    else if ((undefined8 *)((long)puStack_3e0 - (long)puStack_3e8) < puVar41) {
      if (((ulong)puVar41 & 0x7fffffffffffffff) >> 0x3e != 0) {
        func_0x00108ee8(&puStack_3f0);
        goto LAB_0152ad58;
      }
      puVar25 = (undefined8 *)(((long)puStack_3e0 - (long)puStack_3f0) * 2);
      if (puVar25 < puVar46 || (long)puVar25 + (long)puVar41 * -2 == 0) {
        puVar25 = puVar46;
      }
      if (0x3ffffffffffffffe < (ulong)((long)puStack_3e0 - (long)puStack_3f0)) {
        puVar25 = (undefined8 *)0x7fffffffffffffff;
      }
      puVar33 = (undefined8 *)__Znwm(puVar25);
      puVar43 = (undefined8 *)((long)puVar33 + (long)puVar41);
      _bzero(puVar43,puVar41);
      puStack_3f0 = puVar43;
      if (puVar36 != puVar24) {
        puVar32 = puVar36;
        puStack_3f0 = puVar33;
        if ((&MACH_HEADER.cpusubtype <= puVar41) && (0x3f < (ulong)((long)puVar24 - (long)puVar33)))
        {
          if ((undefined8 *)((long)&segment_command_00000020.vmaddr + 7) < puVar41) {
            puVar22 = (undefined8 *)((ulong)puVar41 & 0xffffffffffffffc0);
            puVar26 = (undefined8 *)((long)puVar33 + (long)puVar41 + -0x20);
            puVar27 = puVar36 + -4;
            puVar32 = puVar22;
            do {
              uVar49 = *puVar27;
              uVar14 = puVar27[3];
              uVar13 = puVar27[2];
              uVar53 = puVar27[-3];
              uVar52 = puVar27[-4];
              uVar51 = puVar27[-1];
              uVar50 = puVar27[-2];
              puVar26[1] = puVar27[1];
              *puVar26 = uVar49;
              puVar26[3] = uVar14;
              puVar26[2] = uVar13;
              puVar26[-3] = uVar53;
              puVar26[-4] = uVar52;
              puVar26[-1] = uVar51;
              puVar26[-2] = uVar50;
              puVar26 = puVar26 + -8;
              puVar27 = puVar27 + -8;
              puVar32 = puVar32 + -8;
            } while (puVar32 != (undefined8 *)0x0);
            if (puVar41 == puVar22) goto LAB_0152a798;
            if (((ulong)puVar41 & 0x38) == 0) {
              puVar43 = (undefined8 *)((long)puVar43 - (long)puVar22);
              puVar32 = (undefined8 *)((long)puVar36 - (long)puVar22);
              goto LAB_0152a784;
            }
          }
          else {
            puVar22 = (undefined8 *)0x0;
          }
          puVar27 = (undefined8 *)((ulong)puVar41 & 0xfffffffffffffff8);
          puVar32 = (undefined8 *)((long)puVar36 - (long)puVar27);
          puVar43 = (undefined8 *)((long)puVar43 - (long)puVar27);
          puVar36 = (undefined8 *)((long)puVar36 - (long)puVar22);
          puVar26 = (undefined8 *)((long)puVar33 + ((long)puVar36 - (long)puVar24));
          lVar35 = (long)puVar22 - (long)puVar27;
          do {
            puVar36 = puVar36 + -1;
            puVar26 = puVar26 + -1;
            *puVar26 = *puVar36;
            lVar35 = lVar35 + 8;
          } while (lVar35 != 0);
          if (puVar41 == puVar27) goto LAB_0152a798;
        }
LAB_0152a784:
        do {
          puVar43 = (undefined8 *)((long)puVar43 + -1);
          puVar32 = (undefined8 *)((long)puVar32 + -1);
          *(undefined1 *)puVar43 = *(undefined1 *)puVar32;
        } while (puVar32 != puVar24);
      }
LAB_0152a798:
      puStack_3e0 = (undefined8 *)((long)puVar33 + (long)puVar25);
      puStack_3e8 = (undefined8 *)((long)puVar33 + (long)puVar46);
      if (puVar24 != (undefined8 *)0x0) {
        __ZdlPv(puVar24);
      }
    }
    else {
      puVar36 = (undefined8 *)((long)puStack_3e8 + (long)puVar41);
      _bzero(puStack_3e8,puVar41);
      puStack_3e8 = puVar36;
    }
    puStack_3f8 = (undefined8 *)((long)puStack_3f0 + ((long)puVar30 - (long)puVar24));
    lStack_400 = (long)puStack_3e8 - (long)puStack_3f8;
  }
  uVar29 = (long)puStack_3f8 - (long)puStack_3f0;
  uVar19 = (long)puStack_3e8 - (long)puStack_3f0;
  uVar47 = uVar29 - uVar19;
  if (uVar29 < uVar19 || uVar47 == 0) {
    plVar37 = plStack_408;
    if (uVar29 < uVar19) {
      puStack_3e8 = (undefined8 *)((long)puStack_3f0 + uVar29);
    }
  }
  else if ((ulong)((long)puStack_3e0 - (long)puStack_3e8) < uVar47) {
    if ((long)uVar29 < 0) {
      func_0x00108ee8(&puStack_3f0);
      goto LAB_0152ad58;
    }
    uVar20 = ((long)puStack_3e0 - (long)puStack_3f0) * 2;
    if (uVar20 < uVar29 || uVar20 - uVar29 == 0) {
      uVar20 = uVar29;
    }
    if (0x3ffffffffffffffe < (ulong)((long)puStack_3e0 - (long)puStack_3f0)) {
      uVar20 = 0x7fffffffffffffff;
    }
    puVar33 = (undefined8 *)__Znwm(uVar20);
    puVar30 = (undefined8 *)((long)puVar33 + uVar19);
    puVar46 = (undefined8 *)((long)puVar33 + uVar20);
    _bzero(puVar30,uVar47);
    plVar37 = plStack_408;
    puVar41 = puVar30;
    if (puVar36 != puVar24) {
      puVar25 = puVar36;
      puVar41 = puVar33;
      if ((7 < uVar19) && (0x3f < (ulong)((long)puVar24 - (long)puVar33))) {
        if (uVar19 < 0x40) {
          uVar23 = 0;
        }
        else {
          uVar23 = uVar19 & 0xffffffffffffffc0;
          puVar25 = (undefined8 *)((long)puVar33 + (uVar19 - 0x20));
          puVar43 = puVar36 + -4;
          uVar20 = uVar23;
          do {
            uVar50 = *puVar43;
            uVar49 = puVar43[3];
            uVar14 = puVar43[2];
            uVar54 = puVar43[-3];
            uVar53 = puVar43[-4];
            uVar52 = puVar43[-1];
            uVar51 = puVar43[-2];
            puVar25[1] = puVar43[1];
            *puVar25 = uVar50;
            puVar25[3] = uVar49;
            puVar25[2] = uVar14;
            puVar25[-3] = uVar54;
            puVar25[-4] = uVar53;
            puVar25[-1] = uVar52;
            puVar25[-2] = uVar51;
            puVar25 = puVar25 + -8;
            puVar43 = puVar43 + -8;
            uVar20 = uVar20 - 0x40;
          } while (uVar20 != 0);
          if (uVar19 == uVar23) goto LAB_0152a928;
          if ((uVar19 & 0x38) == 0) {
            puVar30 = (undefined8 *)((long)puVar30 - uVar23);
            puVar25 = (undefined8 *)((long)puVar36 - uVar23);
            goto LAB_0152a914;
          }
        }
        uVar20 = uVar19 & 0xfffffffffffffff8;
        puVar25 = (undefined8 *)((long)puVar36 - uVar20);
        puVar30 = (undefined8 *)((long)puVar30 - uVar20);
        puVar36 = (undefined8 *)((long)puVar36 + (-8 - uVar23));
        lVar11 = (long)puVar36 - (long)puVar24;
        lVar35 = uVar23 - uVar20;
        do {
          *(undefined8 *)((long)puVar33 + lVar11) = *puVar36;
          lVar11 = lVar11 + -8;
          lVar35 = lVar35 + 8;
          puVar36 = puVar36 + -1;
        } while (lVar35 != 0);
        if (uVar19 == uVar20) goto LAB_0152a928;
      }
LAB_0152a914:
      do {
        puVar30 = (undefined8 *)((long)puVar30 + -1);
        puVar25 = (undefined8 *)((long)puVar25 + -1);
        *(undefined1 *)puVar30 = *(undefined1 *)puVar25;
      } while (puVar25 != puVar24);
    }
LAB_0152a928:
    puStack_3f0 = puVar41;
    puStack_3e8 = (undefined8 *)((long)puVar33 + uVar29);
    puStack_3e0 = puVar46;
    if (puVar24 != (undefined8 *)0x0) {
      __ZdlPv(puVar24);
    }
  }
  else {
    puVar30 = (undefined8 *)((long)puStack_3e8 + uVar47);
    _bzero(puStack_3e8,uVar47);
    plVar37 = plStack_408;
    puStack_3e8 = puVar30;
  }
  if ((int)uVar13 == 0) {
    plVar17 = (long *)((long)puStack_3e8 - (long)puStack_3f0);
    __ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5writeEPKcl(plVar37);
    if (*(int *)((long)plVar37 + *(long *)(*plVar37 + -0x18) + 0x20) == 0) {
      if (puStack_3f0 != (undefined8 *)0x0) {
        puStack_3e8 = puStack_3f0;
        __ZdlPv();
      }
      lStack_388 = 0;
      if (lVar21 != 0) {
        func_0x00f183cc(lVar21);
      }
      func_0x01194dbc(auStack_248);
      func_0x01194dbc(auStack_190);
      uVar14 = 0;
      if (*(long *)PTR____stack_chk_guard_01d15188 != lStack_d8) {
        do {
          auVar55 = ___stack_chk_fail(uVar14);
          uVar14 = auVar55._0_8_;
          auVar56._8_8_ = lVar21;
          auVar56._0_8_ = uVar14;
          if (auVar55._8_4_ != 0) {
LAB_0152afd4:
            lVar21 = auVar56._0_8_;
            func_0x000e3a54(lVar21);
            uStack_418 = 0x152afdc;
            pppuStack_460 = &ppuStack_420;
            uStack_438 = *(undefined8 *)PTR____stack_chk_guard_01d15188;
            uStack_439 = 5;
            uStack_450 = 0x6d756874;
            uStack_44c = 0x62;
            puStack_478 = puVar24;
            uStack_458 = 0x152b02c;
            lStack_4c8 = *(long *)PTR____stack_chk_guard_01d15188;
            uStack_4b0 = uVar19;
            puStack_4a8 = puVar46;
            uStack_4a0 = uVar47;
            puStack_498 = puVar41;
            puStack_490 = puVar33;
            uStack_488 = uVar13;
            plStack_480 = plVar37;
            uStack_470 = auVar56._8_8_;
            lStack_468 = lVar21;
            uStack_430 = auVar56._8_8_;
            lStack_428 = lVar21;
            ppuStack_420 = &puStack_70;
            func_0x0074aff4();
            if (((*(int *)((long)plVar17 + *(long *)(*plVar17 + -0x18) + 0x20) != 0) ||
                (__ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgExNS_8ios_base7seekdirE
                           (plVar17,0,2),
                *(int *)((long)plVar17 + *(long *)(*plVar17 + -0x18) + 0x20) != 0)) ||
               (__ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5tellgEv(auStack_620,plVar17),
               0x7ffffffffffffffe < uStack_5a0)) {
LAB_0152b148:
              uVar12 = 0x15;
              goto LAB_0152b14c;
            }
            uStack_4d0 = 0;
            uStack_4e8 = 0;
            uStack_4f0 = 0;
            uStack_4d8 = 0;
            uStack_4e0 = 0;
            uStack_508 = 0;
            uStack_510 = 0;
            uStack_4f8 = 0;
            uStack_500 = 0;
            uStack_528 = 0;
            uStack_530 = 0;
            uStack_518 = 0;
            uStack_520 = 0;
            uStack_548 = 0;
            uStack_550 = 0;
            uStack_538 = 0;
            uStack_540 = 0;
            __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgENS_4fposI11__mbstate_tEE
                      (plVar17,&uStack_550);
            if (*(int *)((long)plVar17 + *(long *)(*plVar17 + -0x18) + 0x20) != 0)
            goto LAB_0152b148;
            if (uStack_5a0 == 0) {
              lVar21 = 0;
            }
            else {
              lVar21 = __Znwm(uStack_5a0);
              _bzero(lVar21,uStack_5a0);
            }
            __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(plVar17,lVar21,uStack_5a0);
            lStack_6f0 = 0;
            lStack_6e8 = 0;
            uStack_6e0 = 0;
            plVar17 = (long *)func_0x00f5b2a4(0);
            iVar7 = func_0x00f5bb20(plVar17,&UNK_00001540);
            if (iVar7 == 0) {
              iVar7 = func_0x00f5baa8(plVar17,&__Z21ImgCoreParallelRunnerPvS_PFiS_mEPFvS_jmEjj,0);
              if (iVar7 != 0) {
                pcVar16 = "JxlDecoderSetParallelRunner failed";
                goto LAB_0152b220;
              }
              iVar7 = func_0x00f5bb74(plVar17,0);
              if (iVar7 != 0) {
                pcVar16 = "JxlDecoderSetCoalescing failed";
                goto LAB_0152b220;
              }
              uStack_708 = _UNK_01a9bd88;
              uStack_710 = _UNK_01a9bd80;
              uStack_700 = 0;
              iVar7 = func_0x00f5bb9c(plVar17,lVar21,uStack_5a0);
              if (iVar7 == 0) {
                func_0x00f5bbe4(plVar17);
                func_0x00f5bbf0(plVar17);
                iVar7 = func_0x00f5f3c4(plVar17,auStack_620);
                if (iVar7 == 0) {
                  func_0x011947c8(auStack_6d8);
                  uVar42 = 0;
                  uVar9 = 0;
                  pcStack_780 = "Decoder error in LoadImageBest";
                  pcStack_798 = "JxlDecoderImageOutBufferSize failed";
                  pcStack_790 = "JxlDecoderGetICCProfileSize failed";
                  uVar44 = 0;
                  uVar4 = 0;
                  goto LAB_0152b308;
                }
                pcVar16 = "JxlDecoderGetBasicInfo failed";
              }
              else {
                pcVar16 = "JxlDecoderSetInput failed";
              }
              func_0x00574408(pcVar16);
            }
            else {
              pcVar16 = "JxlDecoderSubscribeEvents failed";
LAB_0152b220:
              func_0x00574408(pcVar16);
            }
            uVar12 = 0x15;
            goto joined_r0x0152b53c;
          }
          do {
            auVar56 = __Unwind_Resume(uVar14);
            lVar21 = auVar56._8_8_;
            uVar14 = auVar56._0_8_;
          } while (auVar56._8_4_ == 0);
          func_0x01194dbc(auStack_190);
          if (auVar56._8_4_ != 2) goto LAB_0152afd4;
          plVar15 = (long *)___cxa_begin_catch(uVar14);
          uStack_410 = (**(code **)(*plVar15 + 0x10))();
          func_0x00574408("JPEG_XL::Save: %s");
          ___cxa_end_catch();
          uVar14 = 0x1d;
        } while (*(long *)PTR____stack_chk_guard_01d15188 != lStack_d8);
      }
      return uVar14;
    }
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"Could not write bytes to file");
  }
  else {
    uVar12 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar12,"JxlEncoderProcessOutput failed");
  }
  ___cxa_throw(uVar12,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
LAB_0152ad58:
                    /* WARNING: Does not return */
  pcVar5 = (code *)SoftwareBreakpoint(1,0x152ad5c);
  (*pcVar5)();
LAB_0152b308:
  uVar40 = uVar4;
  iVar7 = func_0x00f5bbf0(plVar17);
  uVar4 = uVar40;
  if (iVar7 < 0x100) {
    switch(iVar7) {
    case 0:
      if ((uVar9 & 1) != 0) {
        func_0x0152b8b4(auStack_6d8,extraout_x1_00);
        func_0x0074aff4();
        if (__DEBUG_DISK_LATENCY != 0) {
          func_0x00574108("Proxy load time: %i ms");
        }
        uVar12 = 0;
        func_0x01194dbc(auStack_6d8);
joined_r0x0152b53c:
        while( true ) {
          if (plVar17 != (long *)0x0) {
            func_0x00f5b548(plVar17);
          }
          if (lStack_6f0 != 0) {
            lStack_6e8 = lStack_6f0;
            __ZdlPv();
          }
          if (lVar21 != 0) {
            __ZdlPv(lVar21);
          }
LAB_0152b14c:
          if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_4c8) break;
          ___stack_chk_fail();
LAB_0152b5d8:
          func_0x00574408("JxlDecoderGetFrameHeader failed");
LAB_0152b594:
          uVar12 = 0x15;
          func_0x01194dbc(auStack_6d8);
        }
        return uVar12;
      }
      pcStack_780 = "Proxy: Cannot find JXL frame";
      break;
    case 1:
      break;
    case 2:
      pcStack_780 = "Error, already provided all input";
      break;
    default:
LAB_0152b568:
      pcStack_780 = "Unknown decoder status";
      break;
    case 5:
      if ((uVar40 & 1) == 0) {
        func_0x01195d64(auStack_6d8,uVar42,uVar44,0,4,0);
        func_0x01195d64(extraout_x1_00,uVar42,uVar44,uVar12,3,0x20);
        lVar35 = func_0x0152b6ac(auStack_6d8);
        iVar7 = func_0x00f5f784(plVar17,&uStack_710,&lStack_748);
        if (iVar7 == 0) {
          if (lStack_748 != lVar35) {
            func_0x00574408("Invalid out buffer size: wanted=%llu alloc=%llu");
            goto LAB_0152b594;
          }
          uVar13 = func_0x01196ea8(auStack_6d8);
          iVar7 = func_0x00f5fa94(plVar17,&uStack_710,uVar13,lVar35);
          if (iVar7 == 0) goto LAB_0152b308;
          pcStack_798 = "JxlDecoderSetImageOutBuffer failed";
        }
        func_0x00574408(pcStack_798);
        goto LAB_0152b594;
      }
      iVar7 = func_0x00f5b898(plVar17);
      if (iVar7 == 0) goto LAB_0152b308;
      pcStack_780 = "JxlDecoderSkipCurrentFrame failed";
    }
    func_0x00574408(pcStack_780);
    goto LAB_0152b594;
  }
  if (iVar7 == 0x100) {
    iVar7 = func_0x00f5f65c(plVar17,&uStack_710,1,&lStack_748);
    if (iVar7 != 0) goto LAB_0152b55c;
    func_0x00f9db28(&lStack_6f0,lStack_748);
    iVar7 = func_0x00f5f6cc(plVar17,&uStack_710,1,lStack_6f0,lStack_6e8 - lStack_6f0);
    if (iVar7 != 0) {
      pcStack_790 = "JxlDecoderGetColorAsICCProfile failed";
LAB_0152b55c:
      func_0x00574408(pcStack_790);
      goto LAB_0152b594;
    }
  }
  else if (iVar7 != 0x1000) {
    if (iVar7 != 0x400) goto LAB_0152b568;
    uVar2 = uVar9 & 1;
    uVar4 = 1;
    uVar9 = 1;
    if (uVar2 == 0) {
      iVar7 = func_0x00f5fc48(plVar17,&lStack_748);
      if (iVar7 != 0) goto LAB_0152b5d8;
      lStack_760 = 0;
      lStack_758 = 0;
      uStack_750 = 0;
      func_0x005fc8d0(&lStack_760,iStack_740 + 1);
      iVar7 = func_0x00f5fe90(plVar17,lStack_760,lStack_758 - lStack_760);
      if (iVar7 == 0) {
        func_0x0152b820(auStack_778,lStack_760,iStack_740);
        uVar9 = func_0x002fa510(auStack_778,&uStack_450);
        uVar45 = uStack_728;
        uVar3 = uStack_72c;
        if (uVar9 == 0) {
          uVar45 = uVar44;
          uVar3 = uVar42;
        }
        uVar42 = uVar3;
        if (cStack_761 < '\0') {
          __ZdlPv(auStack_778[0]);
        }
        uVar40 = uVar9 ^ 1;
      }
      else {
        func_0x00574408("JxlDecoderGetFrameName failed");
        uVar9 = 0;
        uVar45 = uVar44;
      }
      if (lStack_760 != 0) {
        lStack_758 = lStack_760;
        __ZdlPv();
      }
      uVar44 = uVar45;
      uVar4 = uVar40;
      if (iVar7 != 0) goto LAB_0152b594;
    }
  }
  goto LAB_0152b308;
}


/* __ZNK5Proxy7JPEG_XL4SaveERNSt3__114basic_ofstreamIcNS1_11char_traitsIcEEEERNS_15BackendSaveInfoE @ 01529c88 */

/* WARNING: Possible PIC construction at 0x0152b028: Changing call to branch */
/* WARNING: Removing unreachable block (ram,0x0152b02c) */
/* WARNING: Removing unreachable block (ram,0x0152b038) */
/* WARNING: Removing unreachable block (ram,0x0152b040) */
/* WARNING: Removing unreachable block (ram,0x0152b06c) */
/* WARNING: Removing unreachable block (ram,0x0152b058) */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8
__ZNK5Proxy7JPEG_XL4SaveERNSt3__114basic_ofstreamIcNS1_11char_traitsIcEEEERNS_15BackendSaveInfoE
          (undefined8 param_1,long *param_2,long param_3)

{
  int iVar1;
  uint uVar2;
  undefined8 *puVar3;
  undefined4 uVar4;
  uint uVar5;
  code *pcVar6;
  int iVar7;
  uint uVar9;
  int iVar8;
  ulong uVar10;
  undefined8 uVar11;
  undefined8 uVar12;
  undefined8 uVar13;
  long *plVar14;
  char *pcVar15;
  undefined8 extraout_x1;
  long *plVar16;
  int iVar17;
  long lVar18;
  undefined8 *puVar19;
  ulong uVar20;
  undefined8 *puVar21;
  undefined8 *puVar22;
  undefined8 *puVar23;
  int iVar24;
  long lVar25;
  undefined8 *puVar26;
  ulong uVar27;
  long lVar28;
  undefined8 *puVar29;
  ulong uVar30;
  long lVar31;
  long lVar32;
  long *plVar33;
  undefined8 *puVar34;
  uint uVar35;
  undefined8 *unaff_x25;
  undefined8 *puVar36;
  undefined4 uVar37;
  undefined8 *puVar38;
  undefined4 uVar39;
  undefined4 uVar40;
  undefined8 *unaff_x27;
  ulong uVar41;
  float fVar42;
  undefined8 uVar43;
  undefined8 uVar44;
  undefined8 uVar45;
  undefined8 uVar46;
  undefined8 uVar47;
  undefined8 uVar48;
  undefined1 auVar49 [12];
  undefined1 auVar50 [16];
  char *pcStack_738;
  char *pcStack_730;
  char *pcStack_720;
  undefined8 auStack_718 [2];
  char cStack_701;
  long lStack_700;
  long lStack_6f8;
  undefined8 uStack_6f0;
  long lStack_6e8;
  int iStack_6e0;
  undefined4 uStack_6cc;
  undefined4 uStack_6c8;
  undefined8 uStack_6b0;
  undefined8 uStack_6a8;
  undefined8 uStack_6a0;
  long lStack_690;
  long lStack_688;
  undefined8 uStack_680;
  undefined1 auStack_678 [184];
  undefined1 auStack_5c0 [128];
  ulong uStack_540;
  undefined8 uStack_4f0;
  undefined8 uStack_4e8;
  undefined8 uStack_4e0;
  undefined8 uStack_4d8;
  undefined8 uStack_4d0;
  undefined8 uStack_4c8;
  undefined8 uStack_4c0;
  undefined8 uStack_4b8;
  undefined8 uStack_4b0;
  undefined8 uStack_4a8;
  undefined8 uStack_4a0;
  undefined8 uStack_498;
  undefined8 uStack_490;
  undefined8 uStack_488;
  undefined8 uStack_480;
  undefined8 uStack_478;
  undefined8 uStack_470;
  long lStack_468;
  ulong uStack_450;
  undefined8 *puStack_448;
  ulong uStack_440;
  undefined8 *puStack_438;
  undefined8 *puStack_430;
  undefined8 uStack_428;
  long *plStack_420;
  undefined8 *puStack_418;
  undefined8 uStack_410;
  long lStack_408;
  undefined1 **ppuStack_400;
  undefined8 uStack_3f8;
  undefined4 uStack_3f0;
  undefined2 uStack_3ec;
  undefined1 uStack_3d9;
  undefined8 uStack_3d8;
  undefined8 uStack_3d0;
  long lStack_3c8;
  undefined1 *puStack_3c0;
  undefined8 uStack_3b8;
  undefined8 uStack_3b0;
  long *plStack_3a8;
  long lStack_3a0;
  undefined8 *puStack_398;
  undefined8 *puStack_390;
  undefined8 *puStack_388;
  undefined8 *puStack_380;
  undefined4 auStack_378 [4];
  undefined4 uStack_368;
  undefined8 uStack_340;
  undefined8 uStack_338;
  undefined8 uStack_330;
  long lStack_328;
  undefined8 uStack_320;
  undefined8 uStack_318;
  undefined8 uStack_310;
  undefined8 uStack_308;
  undefined8 uStack_300;
  undefined8 uStack_2f8;
  undefined8 uStack_2f0;
  undefined8 uStack_2e8;
  undefined8 uStack_2e0;
  undefined8 uStack_2d8;
  undefined8 uStack_2d0;
  undefined8 uStack_2c8;
  undefined8 uStack_2c0;
  int aiStack_2b4 [3];
  undefined8 uStack_2a8;
  undefined4 uStack_2a0;
  undefined4 uStack_290;
  undefined4 uStack_288;
  undefined8 uStack_264;
  undefined8 uStack_25c;
  undefined1 auStack_1e8 [24];
  int iStack_1d0;
  int iStack_1cc;
  int iStack_1c8;
  uint uStack_1c4;
  undefined4 uStack_1c0;
  long lStack_1b0;
  long lStack_1a8;
  undefined1 auStack_130 [24];
  int iStack_118;
  int iStack_114;
  int iStack_110;
  int iStack_10c;
  int iStack_108;
  long lStack_f8;
  long lStack_f0;
  long lStack_78;

  lStack_78 = *(long *)PTR____stack_chk_guard_01d15188;
  lVar31 = *(long *)(param_3 + 0x20);
  func_0x011947c8(auStack_130);
  lVar18 = *(long *)(lVar31 + 0x40);
  if (lVar18 == 0) {
    lVar32 = 0;
    lVar18 = 0;
  }
  else {
    iVar7 = *(int *)(lVar31 + 0x20);
    iVar8 = *(int *)(lVar31 + 0x24);
    iVar17 = *(int *)(lVar31 + 0x18);
    iVar1 = *(int *)(lVar31 + 0x1c);
    iVar24 = 0xc;
    switch(*(undefined4 *)(lVar31 + 0x28)) {
    case 1:
    case 0xd:
      iVar24 = 2;
      break;
    default:
      func_0x015254fc(*(undefined4 *)(lVar31 + 0x28),0,aiStack_2b4,auStack_1e8);
      lVar25 = *(long *)(lVar31 + 0x38);
      lVar18 = *(long *)(lVar31 + 0x40);
      lVar32 = lVar18 + lVar25 * iVar1 + (long)aiStack_2b4[0] * (long)iVar17;
      if (lVar18 == 0) {
        lVar18 = 0;
        goto LAB_01529de4;
      }
      goto LAB_01529d6c;
    case 3:
      iVar24 = 6;
      break;
    case 4:
      break;
    case 0xe:
      iVar24 = 4;
    }
    lVar25 = *(long *)(lVar31 + 0x38);
    lVar32 = lVar18 + lVar25 * iVar1 + (long)iVar24 * (long)iVar17;
LAB_01529d6c:
    iVar17 = *(int *)(lVar31 + 0x18);
    unaff_x25 = (undefined8 *)(long)*(int *)(lVar31 + 0x1c);
    lVar28 = 0xc;
    switch(*(undefined4 *)(lVar31 + 0x28)) {
    case 1:
    case 0xd:
      lVar28 = 2;
      break;
    default:
      func_0x015254fc(*(undefined4 *)(lVar31 + 0x28),0,aiStack_2b4,auStack_1e8);
      lVar28 = (long)aiStack_2b4[0];
      lVar25 = *(long *)(lVar31 + 0x38);
      lVar18 = *(long *)(lVar31 + 0x40);
      break;
    case 3:
      lVar28 = 6;
      break;
    case 4:
      break;
    case 0xe:
      lVar28 = 4;
    }
    lVar18 = lVar18 + lVar28 * ((long)iVar17 + (long)iVar7) +
                      lVar25 * ((long)unaff_x25 + (long)(iVar8 + -1));
  }
LAB_01529de4:
  iVar7 = *(int *)(lVar31 + 0x20);
  iVar8 = *(int *)(lVar31 + 0x24);
  puVar34 = (undefined8 *)(long)iVar8;
  iVar17 = 0xc;
  switch(*(undefined4 *)(lVar31 + 0x28)) {
  case 1:
    if (lVar18 - lVar32 == (long)iVar8 * (long)iVar7 * 2) break;
    goto LAB_01529e80;
  default:
    func_0x015254fc(*(undefined4 *)(lVar31 + 0x28),0,aiStack_2b4,auStack_1e8);
    if (lVar18 - lVar32 != (long)iVar8 * (long)iVar7 * (long)aiStack_2b4[0]) goto LAB_01529e80;
    break;
  case 3:
    if (lVar18 - lVar32 != (long)iVar8 * (long)iVar7 * 6) goto LAB_01529e80;
    break;
  case 4:
    goto code_r0x01529ee0;
  case 0xd:
    iVar17 = 2;
code_r0x01529ee0:
    if (lVar18 - lVar32 == (long)iVar8 * (long)iVar7 * (long)iVar17) break;
LAB_01529e80:
    func_0x01195d64(auStack_130,*(undefined4 *)(lVar31 + 0x20),*(undefined4 *)(lVar31 + 0x24),0,
                    *(undefined4 *)(lVar31 + 0x28),0);
    uVar10 = func_0x01197c24(auStack_130,lVar31);
    if ((uVar10 & 1) == 0) {
      uVar11 = ___cxa_allocate_exception(0x10);
      __ZNSt13runtime_errorC1EPKc(uVar11,"MakeDense: failed to copy buffer");
      ___cxa_throw(uVar11,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18
                  );
      goto LAB_0152ad58;
    }
    goto LAB_01529f10;
  case 0xe:
    if (lVar18 - lVar32 != (long)iVar8 * (long)iVar7 * 4) goto LAB_01529e80;
  }
  func_0x01197340(auStack_130,lVar31,0,0,0);
LAB_01529f10:
  if (iStack_108 != 3) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"Saving proxy: unsupported image format.");
    ___cxa_throw(uVar11,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  func_0x011947c8(auStack_1e8);
  iVar7 = iStack_110;
  if (iStack_110 <= iStack_10c) {
    iVar7 = iStack_10c;
  }
  fVar42 = (float)NEON_fminnm(450.0 / (float)iVar7,0x3f800000);
  uVar11 = 0;
  func_0x01195d64(auStack_1e8,(int)(fVar42 * (float)iStack_110),(int)(fVar42 * (float)iStack_10c),0,
                  3,0);
  func_0x014bd6f4(auStack_130,auStack_1e8,&__ZN4ICPP19ResizeSuper_16u_C3REPK12CImageBufferPS0_dddd);
  lVar18 = func_0x00f178e4(0);
  lStack_328 = lVar18;
  iVar7 = func_0x00f18588(lVar18,&__Z21ImgCoreParallelRunnerPvS_PFiS_mEPFvS_jmEjj,0);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderSetParallelRunner failed");
    ___cxa_throw(uVar11,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  iVar7 = func_0x00f1862c(lVar18);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderUseBoxes failed");
LAB_0152aa98:
    ___cxa_throw(uVar11,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  iVar7 = func_0x00f18658(lVar18,&__ZN5ProxyL14JXLBOX_VERSIONE,param_3 + 4,4,0);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderAddBox failed: version");
    goto LAB_0152aa98;
  }
  iVar7 = func_0x00f18658(lVar18,&__ZN5ProxyL15JXLBOX_METADATAE,*(long *)(param_3 + 8),
                          *(long *)(param_3 + 0x10) - *(long *)(param_3 + 8),0);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderAddBox failed: metadata");
    goto LAB_0152aa98;
  }
  func_0x00f19838(lVar18);
  uStack_330 = 0;
  uStack_338 = _UNK_01a9bd70;
  uStack_340 = _UNK_01a9bd68;
  func_0x00f16bfc(aiStack_2b4);
  aiStack_2b4[0] = 1;
  uStack_2a8 = _UNK_01a9bec8;
  uStack_2a0 = 0x44fa0000;
  if (*(char *)(param_3 + 0x29) != '\0') {
    uStack_2a0 = 0x47435000;
  }
  uStack_290 = 0;
  uStack_288 = 1;
  uStack_25c = _UNK_017d9748;
  uStack_264 = _UNK_017d9740;
  iVar7 = func_0x00f16c48(lVar18,aiStack_2b4);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderSetBasicInfo failed");
    ___cxa_throw(uVar11,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  uStack_2c0 = 0;
  uStack_2d8 = 0;
  uStack_2e0 = 0;
  uStack_2c8 = 0;
  uStack_2d0 = 0;
  uStack_2f8 = 0;
  uStack_300 = 0;
  uStack_2e8 = 0;
  uStack_2f0 = 0;
  uStack_318 = 0;
  uStack_320 = 0;
  uStack_308 = 0;
  uStack_310 = 0;
  func_0x00f1a0bc(&uStack_320,0);
  iVar7 = func_0x00f16b60(lVar18,&uStack_320);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderSetColorEncoding failed");
    ___cxa_throw(uVar11,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  uVar12 = func_0x00f171b4(lVar18,0);
  uVar13 = func_0x00f171b4(lVar18,0);
  iVar7 = func_0x00f17894(0x3f19999a,uVar12);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderSetFrameDistance failed: proxy");
    ___cxa_throw(uVar11,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  iVar7 = *(int *)(param_3 + 0x2c);
  if (iVar7 != 3) {
    if (iVar7 != 6) {
      func_0x00574348("GetEncodingEffort: Unknown");
    }
    iVar7 = 5;
  }
  iVar7 = func_0x00f174e8(uVar12,0,iVar7);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderFrameSettingsSetOption failed: proxy effort");
LAB_0152abf4:
    ___cxa_throw(uVar11,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  iVar7 = func_0x00f174e8(uVar12,10,0);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderFrameSettingsSetOption failed: proxy gaborish");
    goto LAB_0152abf4;
  }
  iVar7 = func_0x00f174e8(uVar12,0xb,0);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderFrameSettingsSetOption failed: proxy modular");
    goto LAB_0152abf4;
  }
  iVar7 = func_0x00f17894(0x3dcccccd,uVar13);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderSetFrameDistance failed: thumb");
    goto LAB_0152abf4;
  }
  iVar7 = func_0x00f174e8(uVar13,0,5);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderFrameSettingsSetOption failed: thumb effort");
    goto LAB_0152abf4;
  }
  iVar7 = func_0x00f174e8(uVar13,0xb,0);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderFrameSettingsSetOption failed: thumb modular");
    goto LAB_0152abf4;
  }
  func_0x00f16c30(auStack_378);
  auStack_378[0] = 1;
  uStack_368 = 1;
  iVar7 = func_0x00f19ecc(uVar13,auStack_378);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderSetFrameHeader failed: thumb");
LAB_0152ac44:
    ___cxa_throw(uVar11,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  iVar8 = func_0x00f19f68(uVar13,"thumb");
  iVar7 = iStack_1d0;
  if (iVar8 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderSetFrameName failed: thumb");
    goto LAB_0152ac44;
  }
  if (lStack_1a8 == 0) {
    lVar32 = 0;
    lVar31 = 0;
    lStack_1a8 = 0;
  }
  else {
    puVar34 = (undefined8 *)(ulong)uStack_1c4;
    unaff_x25 = (undefined8 *)(long)iStack_1cc;
    iVar8 = 0xc;
    switch(uStack_1c0) {
    case 1:
    case 0xd:
      iVar8 = 2;
      break;
    default:
      func_0x015254fc(uStack_1c0,0,&puStack_390,&puStack_398);
      lVar31 = lStack_1a8 + lStack_1b0 * (long)unaff_x25 + (long)(int)puStack_390 * (long)iVar7;
      if (lStack_1a8 == 0) {
        lVar32 = 0;
        lStack_1a8 = 0;
        goto LAB_0152a3a8;
      }
      goto LAB_0152a29c;
    case 3:
      iVar8 = 6;
      break;
    case 4:
      break;
    case 0xe:
      iVar8 = 4;
    }
    lVar31 = lStack_1a8 + lStack_1b0 * (long)unaff_x25 + (long)iVar8 * (long)iStack_1d0;
LAB_0152a29c:
    lVar25 = (long)iStack_1d0;
    puVar34 = (undefined8 *)((long)iStack_1cc + (long)(int)(uStack_1c4 - 1));
    lVar32 = 0xc;
    switch(uStack_1c0) {
    case 1:
    case 0xd:
      lVar32 = 2;
      break;
    default:
      func_0x015254fc(uStack_1c0,0,&puStack_390,&puStack_398);
      lVar32 = lStack_1a8 +
               lStack_1b0 * (int)puVar34 + (long)(int)puStack_390 * (long)(int)(lVar25 + iStack_1c8)
      ;
      if (lStack_1a8 == 0) {
        lStack_1a8 = 0;
        goto LAB_0152a3a8;
      }
      goto LAB_0152a334;
    case 3:
      lVar32 = 6;
      break;
    case 4:
      break;
    case 0xe:
      lVar32 = 4;
    }
    lVar32 = lStack_1a8 + lVar32 * (lVar25 + iStack_1c8) + lStack_1b0 * (long)puVar34;
LAB_0152a334:
    puVar34 = (undefined8 *)(long)iStack_1d0;
    unaff_x25 = (undefined8 *)(long)iStack_1cc;
    iVar7 = 0xc;
    switch(uStack_1c0) {
    case 1:
    case 0xd:
      iVar7 = 2;
      break;
    default:
      func_0x015254fc(uStack_1c0,0,&puStack_390,&puStack_398);
      iVar7 = (int)puStack_390;
      break;
    case 3:
      iVar7 = 6;
      break;
    case 4:
      break;
    case 0xe:
      iVar7 = 4;
    }
    lStack_1a8 = lStack_1a8 + lStack_1b0 * (long)unaff_x25 + (long)iVar7 * (long)iStack_1d0;
  }
LAB_0152a3a8:
  iVar7 = func_0x00f18e3c(uVar13,&uStack_340,lStack_1a8,lVar32 - lVar31);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderAddImageFrame failed: thumb");
LAB_0152acb0:
    ___cxa_throw(uVar11,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  uStack_368 = 0;
  iVar7 = func_0x00f19ecc(uVar12,auStack_378);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderSetFrameHeader failed: proxy");
    goto LAB_0152acb0;
  }
  iVar8 = func_0x00f19f68(uVar12,"proxy");
  iVar7 = iStack_118;
  if (iVar8 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderSetFrameName failed: proxy");
    goto LAB_0152acb0;
  }
  if (lStack_f0 == 0) {
    lVar32 = 0;
    lVar31 = 0;
    lStack_f0 = 0;
  }
  else {
    puVar34 = (undefined8 *)(long)iStack_114;
    iVar8 = 0xc;
    switch(iStack_108) {
    case 1:
    case 0xd:
      iVar8 = 2;
      break;
    default:
      func_0x015254fc(iStack_108,0,&puStack_390,&puStack_398);
      lVar31 = lStack_f0 + lStack_f8 * (long)puVar34 + (long)(int)puStack_390 * (long)iVar7;
      if (lStack_f0 == 0) {
        lVar32 = 0;
        lStack_f0 = 0;
        goto LAB_0152a5a8;
      }
      goto LAB_0152a49c;
    case 3:
      iVar8 = 6;
      break;
    case 4:
      break;
    case 0xe:
      iVar8 = 4;
    }
    lVar31 = lStack_f0 + lStack_f8 * (long)puVar34 + (long)iVar8 * (long)iStack_118;
LAB_0152a49c:
    lVar28 = (long)iStack_118;
    lVar32 = (long)iStack_114 + (long)(iStack_10c + -1);
    lVar25 = 0xc;
    switch(iStack_108) {
    case 1:
    case 0xd:
      lVar25 = 2;
      break;
    default:
      func_0x015254fc(iStack_108,0,&puStack_390,&puStack_398);
      lVar32 = lStack_f0 +
               lStack_f8 * (int)lVar32 + (long)(int)puStack_390 * (long)(int)(lVar28 + iStack_110);
      if (lStack_f0 == 0) {
        lStack_f0 = 0;
        goto LAB_0152a5a8;
      }
      goto LAB_0152a534;
    case 3:
      lVar25 = 6;
      break;
    case 4:
      break;
    case 0xe:
      lVar25 = 4;
    }
    lVar32 = lStack_f0 + lVar25 * (lVar28 + iStack_110) + lStack_f8 * lVar32;
LAB_0152a534:
    puVar34 = (undefined8 *)(long)iStack_114;
    iVar7 = 0xc;
    switch(iStack_108) {
    case 1:
    case 0xd:
      iVar7 = 2;
      break;
    default:
      func_0x015254fc(iStack_108,0,&puStack_390,&puStack_398);
      iVar7 = (int)puStack_390;
      break;
    case 3:
      iVar7 = 6;
      break;
    case 4:
      break;
    case 0xe:
      iVar7 = 4;
    }
    lStack_f0 = lStack_f0 + lStack_f8 * (long)puVar34 + (long)iVar7 * (long)iStack_118;
  }
LAB_0152a5a8:
  iVar7 = func_0x00f18e3c(uVar12,&uStack_340,lStack_f0,lVar32 - lVar31);
  if (iVar7 != 0) {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderAddImageFrame failed: proxy");
    ___cxa_throw(uVar11,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
    goto LAB_0152ad58;
  }
  func_0x00f19844(lVar18);
  plStack_3a8 = param_2;
  puStack_398 = (undefined8 *)__Znwm(0x40);
  puStack_398[5] = 0;
  puStack_398[4] = 0;
  puStack_398[7] = 0;
  puStack_398[6] = 0;
  puStack_398[1] = 0;
  *puStack_398 = 0;
  puStack_398[3] = 0;
  puStack_398[2] = 0;
  puStack_388 = puStack_398 + 8;
  lStack_3a0 = 0x40;
  puStack_390 = puStack_398;
  puStack_380 = puStack_388;
  while( true ) {
    uVar12 = func_0x00f19850(lVar18,&puStack_398,&lStack_3a0);
    puVar29 = puStack_388;
    puVar3 = puStack_390;
    puVar36 = puStack_398;
    if ((int)uVar12 != 2) break;
    unaff_x25 = (undefined8 *)((long)puStack_388 - (long)puStack_390);
    unaff_x27 = (undefined8 *)((long)unaff_x25 * 2);
    if ((long)unaff_x25 < 1) {
      if ((long)unaff_x25 < 0) {
        puStack_388 = (undefined8 *)((long)puStack_390 + (long)unaff_x27);
      }
    }
    else if ((undefined8 *)((long)puStack_380 - (long)puStack_388) < unaff_x25) {
      if (((ulong)unaff_x25 & 0x7fffffffffffffff) >> 0x3e != 0) {
        func_0x00108ee8(&puStack_390);
        goto LAB_0152ad58;
      }
      puVar21 = (undefined8 *)(((long)puStack_380 - (long)puStack_390) * 2);
      if (puVar21 < unaff_x27 || (long)puVar21 + (long)unaff_x25 * -2 == 0) {
        puVar21 = unaff_x27;
      }
      if (0x3ffffffffffffffe < (ulong)((long)puStack_380 - (long)puStack_390)) {
        puVar21 = (undefined8 *)0x7fffffffffffffff;
      }
      puVar34 = (undefined8 *)__Znwm(puVar21);
      puVar38 = (undefined8 *)((long)puVar34 + (long)unaff_x25);
      _bzero(puVar38,unaff_x25);
      puStack_390 = puVar38;
      if (puVar29 != puVar3) {
        puVar26 = puVar29;
        puStack_390 = puVar34;
        if ((&MACH_HEADER.cpusubtype <= unaff_x25) && (0x3f < (ulong)((long)puVar3 - (long)puVar34))
           ) {
          if ((undefined8 *)((long)&segment_command_00000020.vmaddr + 7) < unaff_x25) {
            puVar19 = (undefined8 *)((ulong)unaff_x25 & 0xffffffffffffffc0);
            puVar22 = (undefined8 *)((long)puVar34 + (long)unaff_x25 + -0x20);
            puVar23 = puVar29 + -4;
            puVar26 = puVar19;
            do {
              uVar43 = *puVar23;
              uVar13 = puVar23[3];
              uVar12 = puVar23[2];
              uVar47 = puVar23[-3];
              uVar46 = puVar23[-4];
              uVar45 = puVar23[-1];
              uVar44 = puVar23[-2];
              puVar22[1] = puVar23[1];
              *puVar22 = uVar43;
              puVar22[3] = uVar13;
              puVar22[2] = uVar12;
              puVar22[-3] = uVar47;
              puVar22[-4] = uVar46;
              puVar22[-1] = uVar45;
              puVar22[-2] = uVar44;
              puVar22 = puVar22 + -8;
              puVar23 = puVar23 + -8;
              puVar26 = puVar26 + -8;
            } while (puVar26 != (undefined8 *)0x0);
            if (unaff_x25 == puVar19) goto LAB_0152a798;
            if (((ulong)unaff_x25 & 0x38) == 0) {
              puVar38 = (undefined8 *)((long)puVar38 - (long)puVar19);
              puVar26 = (undefined8 *)((long)puVar29 - (long)puVar19);
              goto LAB_0152a784;
            }
          }
          else {
            puVar19 = (undefined8 *)0x0;
          }
          puVar23 = (undefined8 *)((ulong)unaff_x25 & 0xfffffffffffffff8);
          puVar26 = (undefined8 *)((long)puVar29 - (long)puVar23);
          puVar38 = (undefined8 *)((long)puVar38 - (long)puVar23);
          puVar29 = (undefined8 *)((long)puVar29 - (long)puVar19);
          puVar22 = (undefined8 *)((long)puVar34 + ((long)puVar29 - (long)puVar3));
          lVar31 = (long)puVar19 - (long)puVar23;
          do {
            puVar29 = puVar29 + -1;
            puVar22 = puVar22 + -1;
            *puVar22 = *puVar29;
            lVar31 = lVar31 + 8;
          } while (lVar31 != 0);
          if (unaff_x25 == puVar23) goto LAB_0152a798;
        }
LAB_0152a784:
        do {
          puVar38 = (undefined8 *)((long)puVar38 + -1);
          puVar26 = (undefined8 *)((long)puVar26 + -1);
          *(undefined1 *)puVar38 = *(undefined1 *)puVar26;
        } while (puVar26 != puVar3);
      }
LAB_0152a798:
      puStack_380 = (undefined8 *)((long)puVar34 + (long)puVar21);
      puStack_388 = (undefined8 *)((long)puVar34 + (long)unaff_x27);
      if (puVar3 != (undefined8 *)0x0) {
        __ZdlPv(puVar3);
      }
    }
    else {
      puVar29 = (undefined8 *)((long)puStack_388 + (long)unaff_x25);
      _bzero(puStack_388,unaff_x25);
      puStack_388 = puVar29;
    }
    puStack_398 = (undefined8 *)((long)puStack_390 + ((long)puVar36 - (long)puVar3));
    lStack_3a0 = (long)puStack_388 - (long)puStack_398;
  }
  uVar30 = (long)puStack_398 - (long)puStack_390;
  uVar41 = (long)puStack_388 - (long)puStack_390;
  uVar10 = uVar30 - uVar41;
  if (uVar30 < uVar41 || uVar10 == 0) {
    plVar33 = plStack_3a8;
    if (uVar30 < uVar41) {
      puStack_388 = (undefined8 *)((long)puStack_390 + uVar30);
    }
  }
  else if ((ulong)((long)puStack_380 - (long)puStack_388) < uVar10) {
    if ((long)uVar30 < 0) {
      func_0x00108ee8(&puStack_390);
      goto LAB_0152ad58;
    }
    uVar27 = ((long)puStack_380 - (long)puStack_390) * 2;
    if (uVar27 < uVar30 || uVar27 - uVar30 == 0) {
      uVar27 = uVar30;
    }
    if (0x3ffffffffffffffe < (ulong)((long)puStack_380 - (long)puStack_390)) {
      uVar27 = 0x7fffffffffffffff;
    }
    puVar34 = (undefined8 *)__Znwm(uVar27);
    puVar36 = (undefined8 *)((long)puVar34 + uVar41);
    unaff_x27 = (undefined8 *)((long)puVar34 + uVar27);
    _bzero(puVar36,uVar10);
    plVar33 = plStack_3a8;
    unaff_x25 = puVar36;
    if (puVar29 != puVar3) {
      puVar21 = puVar29;
      unaff_x25 = puVar34;
      if ((7 < uVar41) && (0x3f < (ulong)((long)puVar3 - (long)puVar34))) {
        if (uVar41 < 0x40) {
          uVar20 = 0;
        }
        else {
          uVar20 = uVar41 & 0xffffffffffffffc0;
          puVar21 = (undefined8 *)((long)puVar34 + (uVar41 - 0x20));
          puVar38 = puVar29 + -4;
          uVar27 = uVar20;
          do {
            uVar44 = *puVar38;
            uVar43 = puVar38[3];
            uVar13 = puVar38[2];
            uVar48 = puVar38[-3];
            uVar47 = puVar38[-4];
            uVar46 = puVar38[-1];
            uVar45 = puVar38[-2];
            puVar21[1] = puVar38[1];
            *puVar21 = uVar44;
            puVar21[3] = uVar43;
            puVar21[2] = uVar13;
            puVar21[-3] = uVar48;
            puVar21[-4] = uVar47;
            puVar21[-1] = uVar46;
            puVar21[-2] = uVar45;
            puVar21 = puVar21 + -8;
            puVar38 = puVar38 + -8;
            uVar27 = uVar27 - 0x40;
          } while (uVar27 != 0);
          if (uVar41 == uVar20) goto LAB_0152a928;
          if ((uVar41 & 0x38) == 0) {
            puVar36 = (undefined8 *)((long)puVar36 - uVar20);
            puVar21 = (undefined8 *)((long)puVar29 - uVar20);
            goto LAB_0152a914;
          }
        }
        uVar27 = uVar41 & 0xfffffffffffffff8;
        puVar21 = (undefined8 *)((long)puVar29 - uVar27);
        puVar36 = (undefined8 *)((long)puVar36 - uVar27);
        puVar29 = (undefined8 *)((long)puVar29 + (-8 - uVar20));
        lVar32 = (long)puVar29 - (long)puVar3;
        lVar31 = uVar20 - uVar27;
        do {
          *(undefined8 *)((long)puVar34 + lVar32) = *puVar29;
          lVar32 = lVar32 + -8;
          lVar31 = lVar31 + 8;
          puVar29 = puVar29 + -1;
        } while (lVar31 != 0);
        if (uVar41 == uVar27) goto LAB_0152a928;
      }
LAB_0152a914:
      do {
        puVar36 = (undefined8 *)((long)puVar36 + -1);
        puVar21 = (undefined8 *)((long)puVar21 + -1);
        *(undefined1 *)puVar36 = *(undefined1 *)puVar21;
      } while (puVar21 != puVar3);
    }
LAB_0152a928:
    puStack_390 = unaff_x25;
    puStack_388 = (undefined8 *)((long)puVar34 + uVar30);
    puStack_380 = unaff_x27;
    if (puVar3 != (undefined8 *)0x0) {
      __ZdlPv(puVar3);
    }
  }
  else {
    puVar36 = (undefined8 *)((long)puStack_388 + uVar10);
    _bzero(puStack_388,uVar10);
    plVar33 = plStack_3a8;
    puStack_388 = puVar36;
  }
  if ((int)uVar12 == 0) {
    plVar16 = (long *)((long)puStack_388 - (long)puStack_390);
    __ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5writeEPKcl(plVar33);
    if (*(int *)((long)plVar33 + *(long *)(*plVar33 + -0x18) + 0x20) == 0) {
      if (puStack_390 != (undefined8 *)0x0) {
        puStack_388 = puStack_390;
        __ZdlPv();
      }
      lStack_328 = 0;
      if (lVar18 != 0) {
        func_0x00f183cc(lVar18);
      }
      func_0x01194dbc(auStack_1e8);
      func_0x01194dbc(auStack_130);
      uVar13 = 0;
      if (*(long *)PTR____stack_chk_guard_01d15188 != lStack_78) {
        do {
          auVar49 = ___stack_chk_fail(uVar13);
          uVar13 = auVar49._0_8_;
          auVar50._8_8_ = lVar18;
          auVar50._0_8_ = uVar13;
          if (auVar49._8_4_ != 0) {
LAB_0152afd4:
            lVar18 = auVar50._0_8_;
            func_0x000e3a54(lVar18);
            uStack_3b8 = 0x152afdc;
            ppuStack_400 = &puStack_3c0;
            uStack_3d8 = *(undefined8 *)PTR____stack_chk_guard_01d15188;
            uStack_3d9 = 5;
            uStack_3f0 = 0x6d756874;
            uStack_3ec = 0x62;
            puStack_418 = puVar3;
            uStack_3f8 = 0x152b02c;
            lStack_468 = *(long *)PTR____stack_chk_guard_01d15188;
            uStack_450 = uVar41;
            puStack_448 = unaff_x27;
            uStack_440 = uVar10;
            puStack_438 = unaff_x25;
            puStack_430 = puVar34;
            uStack_428 = uVar12;
            plStack_420 = plVar33;
            uStack_410 = auVar50._8_8_;
            lStack_408 = lVar18;
            uStack_3d0 = auVar50._8_8_;
            lStack_3c8 = lVar18;
            puStack_3c0 = &stack0xfffffffffffffff0;
            func_0x0074aff4();
            if (((*(int *)((long)plVar16 + *(long *)(*plVar16 + -0x18) + 0x20) != 0) ||
                (__ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgExNS_8ios_base7seekdirE
                           (plVar16,0,2),
                *(int *)((long)plVar16 + *(long *)(*plVar16 + -0x18) + 0x20) != 0)) ||
               (__ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5tellgEv(auStack_5c0,plVar16),
               0x7ffffffffffffffe < uStack_540)) {
LAB_0152b148:
              uVar11 = 0x15;
              goto LAB_0152b14c;
            }
            uStack_470 = 0;
            uStack_488 = 0;
            uStack_490 = 0;
            uStack_478 = 0;
            uStack_480 = 0;
            uStack_4a8 = 0;
            uStack_4b0 = 0;
            uStack_498 = 0;
            uStack_4a0 = 0;
            uStack_4c8 = 0;
            uStack_4d0 = 0;
            uStack_4b8 = 0;
            uStack_4c0 = 0;
            uStack_4e8 = 0;
            uStack_4f0 = 0;
            uStack_4d8 = 0;
            uStack_4e0 = 0;
            __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgENS_4fposI11__mbstate_tEE
                      (plVar16,&uStack_4f0);
            if (*(int *)((long)plVar16 + *(long *)(*plVar16 + -0x18) + 0x20) != 0)
            goto LAB_0152b148;
            if (uStack_540 == 0) {
              lVar18 = 0;
            }
            else {
              lVar18 = __Znwm(uStack_540);
              _bzero(lVar18,uStack_540);
            }
            __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(plVar16,lVar18,uStack_540);
            lStack_690 = 0;
            lStack_688 = 0;
            uStack_680 = 0;
            plVar16 = (long *)func_0x00f5b2a4(0);
            iVar7 = func_0x00f5bb20(plVar16,&UNK_00001540);
            if (iVar7 == 0) {
              iVar7 = func_0x00f5baa8(plVar16,&__Z21ImgCoreParallelRunnerPvS_PFiS_mEPFvS_jmEjj,0);
              if (iVar7 != 0) {
                pcVar15 = "JxlDecoderSetParallelRunner failed";
                goto LAB_0152b220;
              }
              iVar7 = func_0x00f5bb74(plVar16,0);
              if (iVar7 != 0) {
                pcVar15 = "JxlDecoderSetCoalescing failed";
                goto LAB_0152b220;
              }
              uStack_6a8 = _UNK_01a9bd88;
              uStack_6b0 = _UNK_01a9bd80;
              uStack_6a0 = 0;
              iVar7 = func_0x00f5bb9c(plVar16,lVar18,uStack_540);
              if (iVar7 == 0) {
                func_0x00f5bbe4(plVar16);
                func_0x00f5bbf0(plVar16);
                iVar7 = func_0x00f5f3c4(plVar16,auStack_5c0);
                if (iVar7 == 0) {
                  func_0x011947c8(auStack_678);
                  uVar37 = 0;
                  uVar9 = 0;
                  pcStack_720 = "Decoder error in LoadImageBest";
                  pcStack_738 = "JxlDecoderImageOutBufferSize failed";
                  pcStack_730 = "JxlDecoderGetICCProfileSize failed";
                  uVar39 = 0;
                  uVar5 = 0;
                  goto LAB_0152b308;
                }
                pcVar15 = "JxlDecoderGetBasicInfo failed";
              }
              else {
                pcVar15 = "JxlDecoderSetInput failed";
              }
              func_0x00574408(pcVar15);
            }
            else {
              pcVar15 = "JxlDecoderSubscribeEvents failed";
LAB_0152b220:
              func_0x00574408(pcVar15);
            }
            uVar11 = 0x15;
            goto joined_r0x0152b53c;
          }
          do {
            auVar50 = __Unwind_Resume(uVar13);
            lVar18 = auVar50._8_8_;
            uVar13 = auVar50._0_8_;
          } while (auVar50._8_4_ == 0);
          func_0x01194dbc(auStack_130);
          if (auVar50._8_4_ != 2) goto LAB_0152afd4;
          plVar14 = (long *)___cxa_begin_catch(uVar13);
          uStack_3b0 = (**(code **)(*plVar14 + 0x10))();
          func_0x00574408("JPEG_XL::Save: %s");
          ___cxa_end_catch();
          uVar13 = 0x1d;
        } while (*(long *)PTR____stack_chk_guard_01d15188 != lStack_78);
      }
      return uVar13;
    }
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"Could not write bytes to file");
  }
  else {
    uVar11 = ___cxa_allocate_exception(0x10);
    __ZNSt13runtime_errorC1EPKc(uVar11,"JxlEncoderProcessOutput failed");
  }
  ___cxa_throw(uVar11,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18);
LAB_0152ad58:
                    /* WARNING: Does not return */
  pcVar6 = (code *)SoftwareBreakpoint(1,0x152ad5c);
  (*pcVar6)();
LAB_0152b308:
  uVar35 = uVar5;
  iVar7 = func_0x00f5bbf0(plVar16);
  uVar5 = uVar35;
  if (iVar7 < 0x100) {
    switch(iVar7) {
    case 0:
      if ((uVar9 & 1) != 0) {
        func_0x0152b8b4(auStack_678,extraout_x1);
        func_0x0074aff4();
        if (__DEBUG_DISK_LATENCY != 0) {
          func_0x00574108("Proxy load time: %i ms");
        }
        uVar11 = 0;
        func_0x01194dbc(auStack_678);
joined_r0x0152b53c:
        while( true ) {
          if (plVar16 != (long *)0x0) {
            func_0x00f5b548(plVar16);
          }
          if (lStack_690 != 0) {
            lStack_688 = lStack_690;
            __ZdlPv();
          }
          if (lVar18 != 0) {
            __ZdlPv(lVar18);
          }
LAB_0152b14c:
          if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_468) break;
          ___stack_chk_fail();
LAB_0152b5d8:
          func_0x00574408("JxlDecoderGetFrameHeader failed");
LAB_0152b594:
          uVar11 = 0x15;
          func_0x01194dbc(auStack_678);
        }
        return uVar11;
      }
      pcStack_720 = "Proxy: Cannot find JXL frame";
      break;
    case 1:
      break;
    case 2:
      pcStack_720 = "Error, already provided all input";
      break;
    default:
LAB_0152b568:
      pcStack_720 = "Unknown decoder status";
      break;
    case 5:
      if ((uVar35 & 1) == 0) {
        func_0x01195d64(auStack_678,uVar37,uVar39,0,4,0);
        func_0x01195d64(extraout_x1,uVar37,uVar39,uVar11,3,0x20);
        lVar31 = func_0x0152b6ac(auStack_678);
        iVar7 = func_0x00f5f784(plVar16,&uStack_6b0,&lStack_6e8);
        if (iVar7 == 0) {
          if (lStack_6e8 != lVar31) {
            func_0x00574408("Invalid out buffer size: wanted=%llu alloc=%llu");
            goto LAB_0152b594;
          }
          uVar12 = func_0x01196ea8(auStack_678);
          iVar7 = func_0x00f5fa94(plVar16,&uStack_6b0,uVar12,lVar31);
          if (iVar7 == 0) goto LAB_0152b308;
          pcStack_738 = "JxlDecoderSetImageOutBuffer failed";
        }
        func_0x00574408(pcStack_738);
        goto LAB_0152b594;
      }
      iVar7 = func_0x00f5b898(plVar16);
      if (iVar7 == 0) goto LAB_0152b308;
      pcStack_720 = "JxlDecoderSkipCurrentFrame failed";
    }
    func_0x00574408(pcStack_720);
    goto LAB_0152b594;
  }
  if (iVar7 == 0x100) {
    iVar7 = func_0x00f5f65c(plVar16,&uStack_6b0,1,&lStack_6e8);
    if (iVar7 != 0) goto LAB_0152b55c;
    func_0x00f9db28(&lStack_690,lStack_6e8);
    iVar7 = func_0x00f5f6cc(plVar16,&uStack_6b0,1,lStack_690,lStack_688 - lStack_690);
    if (iVar7 != 0) {
      pcStack_730 = "JxlDecoderGetColorAsICCProfile failed";
LAB_0152b55c:
      func_0x00574408(pcStack_730);
      goto LAB_0152b594;
    }
  }
  else if (iVar7 != 0x1000) {
    if (iVar7 != 0x400) goto LAB_0152b568;
    uVar2 = uVar9 & 1;
    uVar5 = 1;
    uVar9 = 1;
    if (uVar2 == 0) {
      iVar7 = func_0x00f5fc48(plVar16,&lStack_6e8);
      if (iVar7 != 0) goto LAB_0152b5d8;
      lStack_700 = 0;
      lStack_6f8 = 0;
      uStack_6f0 = 0;
      func_0x005fc8d0(&lStack_700,iStack_6e0 + 1);
      iVar7 = func_0x00f5fe90(plVar16,lStack_700,lStack_6f8 - lStack_700);
      if (iVar7 == 0) {
        func_0x0152b820(auStack_718,lStack_700,iStack_6e0);
        uVar9 = func_0x002fa510(auStack_718,&uStack_3f0);
        uVar40 = uStack_6c8;
        uVar4 = uStack_6cc;
        if (uVar9 == 0) {
          uVar40 = uVar39;
          uVar4 = uVar37;
        }
        uVar37 = uVar4;
        if (cStack_701 < '\0') {
          __ZdlPv(auStack_718[0]);
        }
        uVar35 = uVar9 ^ 1;
      }
      else {
        func_0x00574408("JxlDecoderGetFrameName failed");
        uVar9 = 0;
        uVar40 = uVar39;
      }
      if (lStack_700 != 0) {
        lStack_6f8 = lStack_700;
        __ZdlPv();
      }
      uVar39 = uVar40;
      uVar5 = uVar35;
      if (iVar7 != 0) goto LAB_0152b594;
    }
  }
  goto LAB_0152b308;
}


/* __ZNK5Proxy7JPEG_XL13LoadImageFastER12CImageBufferRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEEjjj @ 0152afdc */

/* WARNING: Possible PIC construction at 0x0152b028: Changing call to branch */
/* WARNING: Removing unreachable block (ram,0x0152b02c) */
/* WARNING: Removing unreachable block (ram,0x0152b038) */
/* WARNING: Removing unreachable block (ram,0x0152b040) */
/* WARNING: Removing unreachable block (ram,0x0152b06c) */
/* WARNING: Removing unreachable block (ram,0x0152b058) */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8
__ZNK5Proxy7JPEG_XL13LoadImageFastER12CImageBufferRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEEjjj
          (undefined8 param_1,undefined8 param_2,long *param_3,undefined8 param_4,undefined8 param_5
          ,undefined8 param_6)

{
  uint uVar1;
  undefined4 uVar2;
  uint uVar3;
  int iVar4;
  uint uVar5;
  char *pcVar6;
  long lVar7;
  long unaff_x19;
  undefined8 uVar8;
  uint uVar9;
  undefined4 uVar10;
  undefined4 uVar11;
  undefined4 uVar12;
  char *pcStack_388;
  char *pcStack_380;
  char *pcStack_370;
  undefined8 auStack_368 [2];
  char cStack_351;
  long lStack_350;
  long lStack_348;
  undefined8 uStack_340;
  long lStack_338;
  int iStack_330;
  undefined4 uStack_31c;
  undefined4 uStack_318;
  undefined8 uStack_300;
  undefined8 uStack_2f8;
  undefined8 uStack_2f0;
  long lStack_2e0;
  long lStack_2d8;
  undefined8 uStack_2d0;
  undefined1 auStack_2c8 [184];
  undefined1 auStack_210 [128];
  ulong uStack_190;
  undefined8 uStack_140;
  undefined8 uStack_138;
  undefined8 uStack_130;
  undefined8 uStack_128;
  undefined8 uStack_120;
  undefined8 uStack_118;
  undefined8 uStack_110;
  undefined8 uStack_108;
  undefined8 uStack_100;
  undefined8 uStack_f8;
  undefined8 uStack_f0;
  undefined8 uStack_e8;
  undefined8 uStack_e0;
  undefined8 uStack_d8;
  undefined8 uStack_d0;
  undefined8 uStack_c8;
  undefined8 uStack_c0;
  long lStack_b8;
  undefined4 uStack_40;
  undefined2 uStack_3c;
  undefined1 uStack_29;
  undefined8 uStack_28;

  uStack_28 = *(undefined8 *)PTR____stack_chk_guard_01d15188;
  uStack_29 = 5;
  uStack_40 = 0x6d756874;
  uStack_3c = 0x62;
  lStack_b8 = *(long *)PTR____stack_chk_guard_01d15188;
  func_0x0074aff4();
  if (((*(int *)((long)param_3 + *(long *)(*param_3 + -0x18) + 0x20) != 0) ||
      (__ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgExNS_8ios_base7seekdirE(param_3,0,2),
      *(int *)((long)param_3 + *(long *)(*param_3 + -0x18) + 0x20) != 0)) ||
     (__ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5tellgEv(auStack_210,param_3),
     0x7ffffffffffffffe < uStack_190)) {
LAB_0152b148:
    uVar8 = 0x15;
    goto LAB_0152b14c;
  }
  uStack_c0 = 0;
  uStack_d8 = 0;
  uStack_e0 = 0;
  uStack_c8 = 0;
  uStack_d0 = 0;
  uStack_f8 = 0;
  uStack_100 = 0;
  uStack_e8 = 0;
  uStack_f0 = 0;
  uStack_118 = 0;
  uStack_120 = 0;
  uStack_108 = 0;
  uStack_110 = 0;
  uStack_138 = 0;
  uStack_140 = 0;
  uStack_128 = 0;
  uStack_130 = 0;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgENS_4fposI11__mbstate_tEE
            (param_3,&uStack_140);
  if (*(int *)((long)param_3 + *(long *)(*param_3 + -0x18) + 0x20) != 0) goto LAB_0152b148;
  if (uStack_190 == 0) {
    unaff_x19 = 0;
  }
  else {
    unaff_x19 = __Znwm(uStack_190);
    _bzero(unaff_x19,uStack_190);
  }
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(param_3,unaff_x19,uStack_190);
  lStack_2e0 = 0;
  lStack_2d8 = 0;
  uStack_2d0 = 0;
  param_3 = (long *)func_0x00f5b2a4(0);
  iVar4 = func_0x00f5bb20(param_3,&UNK_00001540);
  if (iVar4 == 0) {
    iVar4 = func_0x00f5baa8(param_3,&__Z21ImgCoreParallelRunnerPvS_PFiS_mEPFvS_jmEjj,0);
    if (iVar4 == 0) {
      iVar4 = func_0x00f5bb74(param_3,0);
      if (iVar4 == 0) {
        uStack_2f8 = _UNK_01a9bd88;
        uStack_300 = _UNK_01a9bd80;
        uStack_2f0 = 0;
        iVar4 = func_0x00f5bb9c(param_3,unaff_x19,uStack_190);
        if (iVar4 == 0) {
          func_0x00f5bbe4(param_3);
          func_0x00f5bbf0(param_3);
          iVar4 = func_0x00f5f3c4(param_3,auStack_210);
          if (iVar4 == 0) {
            func_0x011947c8(auStack_2c8);
            uVar10 = 0;
            uVar5 = 0;
            pcStack_370 = "Decoder error in LoadImageBest";
            pcStack_388 = "JxlDecoderImageOutBufferSize failed";
            pcStack_380 = "JxlDecoderGetICCProfileSize failed";
            uVar11 = 0;
            uVar3 = 0;
LAB_0152b308:
            while (uVar9 = uVar3, iVar4 = func_0x00f5bbf0(param_3), uVar3 = uVar9, 0xff < iVar4) {
              if (iVar4 == 0x100) {
                iVar4 = func_0x00f5f65c(param_3,&uStack_300,1,&lStack_338);
                if (iVar4 != 0) goto LAB_0152b55c;
                func_0x00f9db28(&lStack_2e0,lStack_338);
                iVar4 = func_0x00f5f6cc(param_3,&uStack_300,1,lStack_2e0,lStack_2d8 - lStack_2e0);
                if (iVar4 != 0) {
                  pcStack_380 = "JxlDecoderGetColorAsICCProfile failed";
LAB_0152b55c:
                  func_0x00574408(pcStack_380);
                  goto LAB_0152b594;
                }
              }
              else if (iVar4 != 0x1000) {
                if (iVar4 != 0x400) goto LAB_0152b568;
                uVar1 = uVar5 & 1;
                uVar3 = 1;
                uVar5 = 1;
                if (uVar1 == 0) {
                  iVar4 = func_0x00f5fc48(param_3,&lStack_338);
                  if (iVar4 != 0) goto LAB_0152b5d8;
                  lStack_350 = 0;
                  lStack_348 = 0;
                  uStack_340 = 0;
                  func_0x005fc8d0(&lStack_350,iStack_330 + 1);
                  iVar4 = func_0x00f5fe90(param_3,lStack_350,lStack_348 - lStack_350);
                  if (iVar4 == 0) {
                    func_0x0152b820(auStack_368,lStack_350,iStack_330);
                    uVar5 = func_0x002fa510(auStack_368,&uStack_40);
                    uVar12 = uStack_318;
                    uVar2 = uStack_31c;
                    if (uVar5 == 0) {
                      uVar12 = uVar11;
                      uVar2 = uVar10;
                    }
                    uVar10 = uVar2;
                    if (cStack_351 < '\0') {
                      __ZdlPv(auStack_368[0]);
                    }
                    uVar9 = uVar5 ^ 1;
                  }
                  else {
                    func_0x00574408("JxlDecoderGetFrameName failed");
                    uVar5 = 0;
                    uVar12 = uVar11;
                  }
                  if (lStack_350 != 0) {
                    lStack_348 = lStack_350;
                    __ZdlPv();
                  }
                  uVar11 = uVar12;
                  uVar3 = uVar9;
                  if (iVar4 != 0) goto LAB_0152b594;
                }
              }
            }
            switch(iVar4) {
            case 0:
              if ((uVar5 & 1) != 0) {
                func_0x0152b8b4(auStack_2c8,param_2);
                func_0x0074aff4();
                if (__DEBUG_DISK_LATENCY != 0) {
                  func_0x00574108("Proxy load time: %i ms");
                }
                uVar8 = 0;
                func_0x01194dbc(auStack_2c8);
                goto joined_r0x0152b53c;
              }
              pcStack_370 = "Proxy: Cannot find JXL frame";
              break;
            case 1:
              break;
            case 2:
              pcStack_370 = "Error, already provided all input";
              break;
            default:
LAB_0152b568:
              pcStack_370 = "Unknown decoder status";
              break;
            case 5:
              if ((uVar9 & 1) == 0) {
                func_0x01195d64(auStack_2c8,uVar10,uVar11,0,4,0);
                func_0x01195d64(param_2,uVar10,uVar11,param_6,3,0x20);
                lVar7 = func_0x0152b6ac(auStack_2c8);
                iVar4 = func_0x00f5f784(param_3,&uStack_300,&lStack_338);
                if (iVar4 == 0) {
                  if (lStack_338 != lVar7) {
                    func_0x00574408("Invalid out buffer size: wanted=%llu alloc=%llu");
                    goto LAB_0152b594;
                  }
                  uVar8 = func_0x01196ea8(auStack_2c8);
                  iVar4 = func_0x00f5fa94(param_3,&uStack_300,uVar8,lVar7);
                  if (iVar4 == 0) goto LAB_0152b308;
                  pcStack_388 = "JxlDecoderSetImageOutBuffer failed";
                }
                func_0x00574408(pcStack_388);
                goto LAB_0152b594;
              }
              iVar4 = func_0x00f5b898(param_3);
              if (iVar4 == 0) goto LAB_0152b308;
              pcStack_370 = "JxlDecoderSkipCurrentFrame failed";
            }
            func_0x00574408(pcStack_370);
            goto LAB_0152b594;
          }
          pcVar6 = "JxlDecoderGetBasicInfo failed";
        }
        else {
          pcVar6 = "JxlDecoderSetInput failed";
        }
        func_0x00574408(pcVar6);
        goto LAB_0152b224;
      }
      pcVar6 = "JxlDecoderSetCoalescing failed";
    }
    else {
      pcVar6 = "JxlDecoderSetParallelRunner failed";
    }
  }
  else {
    pcVar6 = "JxlDecoderSubscribeEvents failed";
  }
  func_0x00574408(pcVar6);
LAB_0152b224:
  uVar8 = 0x15;
joined_r0x0152b53c:
  while( true ) {
    if (param_3 != (long *)0x0) {
      func_0x00f5b548(param_3);
    }
    if (lStack_2e0 != 0) {
      lStack_2d8 = lStack_2e0;
      __ZdlPv();
    }
    if (unaff_x19 != 0) {
      __ZdlPv(unaff_x19);
    }
LAB_0152b14c:
    if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_b8) break;
    ___stack_chk_fail();
LAB_0152b5d8:
    func_0x00574408("JxlDecoderGetFrameHeader failed");
LAB_0152b594:
    uVar8 = 0x15;
    func_0x01194dbc(auStack_2c8);
  }
  return uVar8;
}


/* __ZN5ProxyL18LoadImageFromFrameER12CImageBufferRNSt3__114basic_ifstreamIcNS2_11char_traitsIcEEEEjjRKNS2_12basic_stringIcS5_NS2_9allocatorIcEEEE @ 0152b070 */

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8
__ZN5ProxyL18LoadImageFromFrameER12CImageBufferRNSt3__114basic_ifstreamIcNS2_11char_traitsIcEEEEjjRKNS2_12basic_stringIcS5_NS2_9allocatorIcEEEE
          (undefined8 param_1,long *param_2,undefined8 param_3,undefined8 param_4)

{
  uint uVar1;
  undefined4 uVar2;
  uint uVar3;
  int iVar4;
  uint uVar5;
  char *pcVar6;
  long lVar7;
  long unaff_x19;
  undefined8 uVar8;
  uint uVar9;
  undefined4 uVar10;
  undefined4 uVar11;
  undefined4 uVar12;
  char *pcStack_348;
  char *pcStack_340;
  char *pcStack_330;
  undefined8 auStack_328 [2];
  char cStack_311;
  long lStack_310;
  long lStack_308;
  undefined8 uStack_300;
  long lStack_2f8;
  int iStack_2f0;
  undefined4 uStack_2dc;
  undefined4 uStack_2d8;
  undefined8 uStack_2c0;
  undefined8 uStack_2b8;
  undefined8 uStack_2b0;
  long lStack_2a0;
  long lStack_298;
  undefined8 uStack_290;
  undefined1 auStack_288 [184];
  undefined1 auStack_1d0 [128];
  ulong uStack_150;
  undefined8 uStack_100;
  undefined8 uStack_f8;
  undefined8 uStack_f0;
  undefined8 uStack_e8;
  undefined8 uStack_e0;
  undefined8 uStack_d8;
  undefined8 uStack_d0;
  undefined8 uStack_c8;
  undefined8 uStack_c0;
  undefined8 uStack_b8;
  undefined8 uStack_b0;
  undefined8 uStack_a8;
  undefined8 uStack_a0;
  undefined8 uStack_98;
  undefined8 uStack_90;
  undefined8 uStack_88;
  undefined8 uStack_80;
  long lStack_78;

  lStack_78 = *(long *)PTR____stack_chk_guard_01d15188;
  func_0x0074aff4();
  if (((*(int *)((long)param_2 + *(long *)(*param_2 + -0x18) + 0x20) != 0) ||
      (__ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgExNS_8ios_base7seekdirE(param_2,0,2),
      *(int *)((long)param_2 + *(long *)(*param_2 + -0x18) + 0x20) != 0)) ||
     (__ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5tellgEv(auStack_1d0,param_2),
     0x7ffffffffffffffe < uStack_150)) {
LAB_0152b148:
    uVar8 = 0x15;
    goto LAB_0152b14c;
  }
  uStack_80 = 0;
  uStack_98 = 0;
  uStack_a0 = 0;
  uStack_88 = 0;
  uStack_90 = 0;
  uStack_b8 = 0;
  uStack_c0 = 0;
  uStack_a8 = 0;
  uStack_b0 = 0;
  uStack_d8 = 0;
  uStack_e0 = 0;
  uStack_c8 = 0;
  uStack_d0 = 0;
  uStack_f8 = 0;
  uStack_100 = 0;
  uStack_e8 = 0;
  uStack_f0 = 0;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgENS_4fposI11__mbstate_tEE
            (param_2,&uStack_100);
  if (*(int *)((long)param_2 + *(long *)(*param_2 + -0x18) + 0x20) != 0) goto LAB_0152b148;
  if (uStack_150 == 0) {
    unaff_x19 = 0;
  }
  else {
    unaff_x19 = __Znwm(uStack_150);
    _bzero(unaff_x19,uStack_150);
  }
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(param_2,unaff_x19,uStack_150);
  lStack_2a0 = 0;
  lStack_298 = 0;
  uStack_290 = 0;
  param_2 = (long *)func_0x00f5b2a4(0);
  iVar4 = func_0x00f5bb20(param_2,&UNK_00001540);
  if (iVar4 == 0) {
    iVar4 = func_0x00f5baa8(param_2,&__Z21ImgCoreParallelRunnerPvS_PFiS_mEPFvS_jmEjj,0);
    if (iVar4 == 0) {
      iVar4 = func_0x00f5bb74(param_2,0);
      if (iVar4 == 0) {
        uStack_2b8 = _UNK_01a9bd88;
        uStack_2c0 = _UNK_01a9bd80;
        uStack_2b0 = 0;
        iVar4 = func_0x00f5bb9c(param_2,unaff_x19,uStack_150);
        if (iVar4 == 0) {
          func_0x00f5bbe4(param_2);
          func_0x00f5bbf0(param_2);
          iVar4 = func_0x00f5f3c4(param_2,auStack_1d0);
          if (iVar4 == 0) {
            func_0x011947c8(auStack_288);
            uVar10 = 0;
            uVar5 = 0;
            pcStack_330 = "Decoder error in LoadImageBest";
            pcStack_348 = "JxlDecoderImageOutBufferSize failed";
            pcStack_340 = "JxlDecoderGetICCProfileSize failed";
            uVar11 = 0;
            uVar3 = 0;
LAB_0152b308:
            while (uVar9 = uVar3, iVar4 = func_0x00f5bbf0(param_2), uVar3 = uVar9, 0xff < iVar4) {
              if (iVar4 == 0x100) {
                iVar4 = func_0x00f5f65c(param_2,&uStack_2c0,1,&lStack_2f8);
                if (iVar4 != 0) goto LAB_0152b55c;
                func_0x00f9db28(&lStack_2a0,lStack_2f8);
                iVar4 = func_0x00f5f6cc(param_2,&uStack_2c0,1,lStack_2a0,lStack_298 - lStack_2a0);
                if (iVar4 != 0) {
                  pcStack_340 = "JxlDecoderGetColorAsICCProfile failed";
LAB_0152b55c:
                  func_0x00574408(pcStack_340);
                  goto LAB_0152b594;
                }
              }
              else if (iVar4 != 0x1000) {
                if (iVar4 != 0x400) goto LAB_0152b568;
                uVar1 = uVar5 & 1;
                uVar3 = 1;
                uVar5 = 1;
                if (uVar1 == 0) {
                  iVar4 = func_0x00f5fc48(param_2,&lStack_2f8);
                  if (iVar4 != 0) goto LAB_0152b5d8;
                  lStack_310 = 0;
                  lStack_308 = 0;
                  uStack_300 = 0;
                  func_0x005fc8d0(&lStack_310,iStack_2f0 + 1);
                  iVar4 = func_0x00f5fe90(param_2,lStack_310,lStack_308 - lStack_310);
                  if (iVar4 == 0) {
                    func_0x0152b820(auStack_328,lStack_310,iStack_2f0);
                    uVar5 = func_0x002fa510(auStack_328,param_4);
                    uVar12 = uStack_2d8;
                    uVar2 = uStack_2dc;
                    if (uVar5 == 0) {
                      uVar12 = uVar11;
                      uVar2 = uVar10;
                    }
                    uVar10 = uVar2;
                    if (cStack_311 < '\0') {
                      __ZdlPv(auStack_328[0]);
                    }
                    uVar9 = uVar5 ^ 1;
                  }
                  else {
                    func_0x00574408("JxlDecoderGetFrameName failed");
                    uVar5 = 0;
                    uVar12 = uVar11;
                  }
                  if (lStack_310 != 0) {
                    lStack_308 = lStack_310;
                    __ZdlPv();
                  }
                  uVar11 = uVar12;
                  uVar3 = uVar9;
                  if (iVar4 != 0) goto LAB_0152b594;
                }
              }
            }
            switch(iVar4) {
            case 0:
              if ((uVar5 & 1) != 0) {
                func_0x0152b8b4(auStack_288,param_1);
                func_0x0074aff4();
                if (__DEBUG_DISK_LATENCY != 0) {
                  func_0x00574108("Proxy load time: %i ms");
                }
                uVar8 = 0;
                func_0x01194dbc(auStack_288);
                goto joined_r0x0152b53c;
              }
              pcStack_330 = "Proxy: Cannot find JXL frame";
              break;
            case 1:
              break;
            case 2:
              pcStack_330 = "Error, already provided all input";
              break;
            default:
LAB_0152b568:
              pcStack_330 = "Unknown decoder status";
              break;
            case 5:
              if ((uVar9 & 1) == 0) {
                func_0x01195d64(auStack_288,uVar10,uVar11,0,4,0);
                func_0x01195d64(param_1,uVar10,uVar11,param_3,3,0x20);
                lVar7 = func_0x0152b6ac(auStack_288);
                iVar4 = func_0x00f5f784(param_2,&uStack_2c0,&lStack_2f8);
                if (iVar4 == 0) {
                  if (lStack_2f8 != lVar7) {
                    func_0x00574408("Invalid out buffer size: wanted=%llu alloc=%llu");
                    goto LAB_0152b594;
                  }
                  uVar8 = func_0x01196ea8(auStack_288);
                  iVar4 = func_0x00f5fa94(param_2,&uStack_2c0,uVar8,lVar7);
                  if (iVar4 == 0) goto LAB_0152b308;
                  pcStack_348 = "JxlDecoderSetImageOutBuffer failed";
                }
                func_0x00574408(pcStack_348);
                goto LAB_0152b594;
              }
              iVar4 = func_0x00f5b898(param_2);
              if (iVar4 == 0) goto LAB_0152b308;
              pcStack_330 = "JxlDecoderSkipCurrentFrame failed";
            }
            func_0x00574408(pcStack_330);
            goto LAB_0152b594;
          }
          pcVar6 = "JxlDecoderGetBasicInfo failed";
        }
        else {
          pcVar6 = "JxlDecoderSetInput failed";
        }
        func_0x00574408(pcVar6);
        goto LAB_0152b224;
      }
      pcVar6 = "JxlDecoderSetCoalescing failed";
    }
    else {
      pcVar6 = "JxlDecoderSetParallelRunner failed";
    }
  }
  else {
    pcVar6 = "JxlDecoderSubscribeEvents failed";
  }
  func_0x00574408(pcVar6);
LAB_0152b224:
  uVar8 = 0x15;
joined_r0x0152b53c:
  while( true ) {
    if (param_2 != (long *)0x0) {
      func_0x00f5b548(param_2);
    }
    if (lStack_2a0 != 0) {
      lStack_298 = lStack_2a0;
      __ZdlPv();
    }
    if (unaff_x19 != 0) {
      __ZdlPv(unaff_x19);
    }
LAB_0152b14c:
    if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_78) break;
    ___stack_chk_fail();
LAB_0152b5d8:
    func_0x00574408("JxlDecoderGetFrameHeader failed");
LAB_0152b594:
    uVar8 = 0x15;
    func_0x01194dbc(auStack_288);
  }
  return uVar8;
}


/* __ZNK5Proxy7JPEG_XL13LoadImageBestER12CImageBufferRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEEjj @ 0152b610 */

undefined8
__ZNK5Proxy7JPEG_XL13LoadImageBestER12CImageBufferRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEEjj
          (undefined8 param_1,undefined8 param_2,undefined8 param_3,undefined8 param_4,
          undefined8 param_5)

{
  undefined8 uVar1;
  undefined4 uStack_40;
  undefined2 uStack_3c;
  undefined2 uStack_3a;
  char cStack_29;
  long lStack_28;

  lStack_28 = *(long *)PTR____stack_chk_guard_01d15188;
  cStack_29 = '\x05';
  uStack_40 = 0x786f7270;
  uStack_3c = 0x79;
  uVar1 = __ZN5ProxyL18LoadImageFromFrameER12CImageBufferRNSt3__114basic_ifstreamIcNS2_11char_traitsIcEEEEjjRKNS2_12basic_stringIcS5_NS2_9allocatorIcEEEE
                    (param_2,param_3,param_5,&uStack_40);
  if (cStack_29 < '\0') {
    __ZdlPv(CONCAT26(uStack_3a,CONCAT24(uStack_3c,uStack_40)));
  }
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_28) {
    return uVar1;
  }
  uVar1 = ___stack_chk_fail();
  return uVar1;
}


/* __ZN5Proxy7JPEG_XLD1Ev @ 0152b6a4 */

void __ZN5Proxy7JPEG_XLD1Ev(void)

{
  return;
}


/* __ZN5Proxy7JPEG_XLD0Ev @ 0152b6a8 */

void __ZN5Proxy7JPEG_XLD0Ev(void)

{
                    /* WARNING: Could not recover jumptable at 0x0156fe64. Too many branches */
                    /* WARNING: Treating indirect jump as call */
  (*(code *)PTR___ZdlPv_01d15060)();
  return;
}


/* __ZNK5Proxy8Metadata9SerializeERNSt3__16vectorIhNS1_9allocatorIhEEEEj @ 0152c928 */

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

bool __ZNK5Proxy8Metadata9SerializeERNSt3__16vectorIhNS1_9allocatorIhEEEEj
               (undefined8 *param_1,long *param_2)

{
  int iVar1;
  long *plVar2;
  byte bVar3;
  int iVar4;
  long lVar5;
  undefined8 *puVar6;
  long lVar7;
  undefined8 uVar8;
  code *pcVar9;
  bool bVar10;
  undefined1 uVar11;
  long lVar12;
  long *plVar13;
  ulong uVar14;
  undefined8 *****pppppuVar15;
  long lVar16;
  long *plVar17;
  ulong uVar18;
  ulong uVar19;
  long lVar20;
  undefined8 *puVar21;
  ulong uVar22;
  ulong uVar23;
  ulong uVar24;
  ulong uVar25;
  int iVar26;
  undefined1 auVar27 [16];
  undefined8 ****ppppuStack_f0;
  ulong uStack_e8;
  undefined8 uStack_e0;
  long lStack_d8;
  ulong uStack_d0;
  ulong uStack_c8;
  ulong uStack_c0;
  ulong uStack_b8;

  lVar20 = *param_2;
  param_2[1] = lVar20;
  if ((char)*(byte *)((long)param_1 + 0x17) < '\0') {
    uVar22 = param_1[1];
    bVar3 = *(byte *)((long)param_1 + 0x2f);
    if (-1 < (char)bVar3) goto LAB_0152c96c;
LAB_0152c998:
    uVar23 = param_1[4];
    bVar3 = *(byte *)((long)param_1 + 0x47);
    if (-1 < (char)bVar3) goto LAB_0152c978;
LAB_0152c9a4:
    uVar24 = param_1[7];
    bVar3 = *(byte *)((long)param_1 + 0x5f);
    if (-1 < (char)bVar3) goto LAB_0152c984;
LAB_0152c9b0:
    uVar25 = param_1[10];
  }
  else {
    uVar22 = (ulong)*(byte *)((long)param_1 + 0x17);
    bVar3 = *(byte *)((long)param_1 + 0x2f);
    if ((char)bVar3 < '\0') goto LAB_0152c998;
LAB_0152c96c:
    uVar23 = (ulong)bVar3;
    bVar3 = *(byte *)((long)param_1 + 0x47);
    if ((char)bVar3 < '\0') goto LAB_0152c9a4;
LAB_0152c978:
    uVar24 = (ulong)bVar3;
    bVar3 = *(byte *)((long)param_1 + 0x5f);
    if ((char)bVar3 < '\0') goto LAB_0152c9b0;
LAB_0152c984:
    uVar25 = (ulong)bVar3;
  }
  uVar14 = (param_1[0xd] - param_1[0xc]) +
           (long)((int)uVar22 + (int)uVar23 + (int)uVar24 + (int)uVar25 + 0x14) + 0x20;
  if (uVar14 == 0) {
LAB_0152ca58:
    uVar8 = ___ZN5ProxyL5MAGICE;
    puVar21 = (undefined8 *)*param_2;
    puVar21[1] = _UNK_01a9c008;
    *puVar21 = uVar8;
    puVar21[2] = _UNK_01a9c010;
    puVar21[3] = uVar14;
    *(int *)(puVar21 + 4) = (int)uVar22;
    *(int *)((long)puVar21 + 0x24) = (int)uVar23;
    *(int *)(puVar21 + 5) = (int)uVar24;
    *(int *)((long)puVar21 + 0x2c) = (int)uVar25;
    uVar22 = param_1[1];
    puVar6 = (undefined8 *)*param_1;
    if (-1 < (char)*(byte *)((long)param_1 + 0x17)) {
      uVar22 = (ulong)*(byte *)((long)param_1 + 0x17);
      puVar6 = param_1;
    }
    _memcpy(puVar21 + 6,puVar6,uVar22);
    uVar22 = param_1[1];
    if (-1 < (char)*(byte *)((long)param_1 + 0x17)) {
      uVar22 = (ulong)*(byte *)((long)param_1 + 0x17);
    }
    uVar23 = param_1[4];
    puVar6 = (undefined8 *)param_1[3];
    if (-1 < (char)*(byte *)((long)param_1 + 0x2f)) {
      uVar23 = (ulong)*(byte *)((long)param_1 + 0x2f);
      puVar6 = param_1 + 3;
    }
    _memcpy((long)puVar21 + uVar22 + 0x31,puVar6,uVar23);
    uVar23 = param_1[4];
    if (-1 < (char)*(byte *)((long)param_1 + 0x2f)) {
      uVar23 = (ulong)*(byte *)((long)param_1 + 0x2f);
    }
    lVar20 = uVar22 + uVar23 + 0x32;
    uVar22 = param_1[7];
    puVar6 = (undefined8 *)param_1[6];
    if (-1 < (char)*(byte *)((long)param_1 + 0x47)) {
      uVar22 = (ulong)*(byte *)((long)param_1 + 0x47);
      puVar6 = param_1 + 6;
    }
    _memcpy((long)puVar21 + lVar20,puVar6,uVar22);
    uVar22 = param_1[7];
    if (-1 < (char)*(byte *)((long)param_1 + 0x47)) {
      uVar22 = (ulong)*(byte *)((long)param_1 + 0x47);
    }
    lVar20 = lVar20 + uVar22 + 1;
    uVar22 = param_1[10];
    puVar6 = (undefined8 *)param_1[9];
    if (-1 < (char)*(byte *)((long)param_1 + 0x5f)) {
      uVar22 = (ulong)*(byte *)((long)param_1 + 0x5f);
      puVar6 = param_1 + 9;
    }
    _memcpy((long)puVar21 + lVar20,puVar6,uVar22);
    uVar22 = param_1[10];
    if (-1 < (char)*(byte *)((long)param_1 + 0x5f)) {
      uVar22 = (ulong)*(byte *)((long)param_1 + 0x5f);
    }
    lVar20 = lVar20 + uVar22 + 1;
    bVar10 = (param_1[0xd] - param_1[0xc]) + lVar20 != param_2[1] - *param_2;
    if (!bVar10) {
      _memcpy((long)puVar21 + lVar20);
    }
    return bVar10;
  }
  uVar18 = param_2[2] - lVar20;
  if (uVar14 <= uVar18) {
    _bzero(lVar20,uVar14);
    param_2[1] = lVar20 + uVar14;
    goto LAB_0152ca58;
  }
  if (-1 < (long)uVar14) {
    uVar19 = uVar18 * 2;
    if (uVar19 < uVar14 || uVar19 - uVar14 == 0) {
      uVar19 = uVar14;
    }
    if (0x3ffffffffffffffe < uVar18) {
      uVar19 = 0x7fffffffffffffff;
    }
    lVar12 = __Znwm(uVar19);
    _bzero(lVar12,uVar14);
    *param_2 = lVar12;
    param_2[1] = lVar12 + uVar14;
    param_2[2] = lVar12 + uVar19;
    if (lVar20 != 0) {
      __ZdlPv(lVar20);
    }
    goto LAB_0152ca58;
  }
  auVar27 = func_0x00108ee8(param_2);
  plVar17 = auVar27._8_8_;
  plVar13 = auVar27._0_8_;
  lStack_d8 = *(long *)PTR____stack_chk_guard_01d15188;
  plVar2 = (long *)*plVar17;
  uStack_d0 = uVar25;
  uStack_c8 = uVar24;
  uStack_c0 = uVar23;
  uStack_b8 = uVar22;
  if ((((ulong)(plVar17[1] - (long)plVar2) < 0x20) ||
      ((*plVar2 != 0x4f65727574706143 || plVar2[1] != 0x4d79786f7250656e) ||
       plVar2[2] != 0x61746164617465)) || ((ulong)(plVar17[1] - (long)plVar2) < (ulong)plVar2[3])) {
    uVar11 = 0x15;
LAB_0152cc6c:
    if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_d8) {
      return (bool)uVar11;
    }
    ___stack_chk_fail(uVar11);
  }
  else {
    iVar26 = (int)plVar2[4];
    iVar1 = iVar26 + (int)((ulong)plVar2[4] >> 0x20) +
            (int)plVar2[5] + (int)((ulong)plVar2[5] >> 0x20) + 0x14;
    uVar11 = 0x15;
    if ((iVar1 < 0) || ((long)(plVar2[3] - 0x30U) < (long)iVar1)) goto LAB_0152cc6c;
    uVar22 = _strlen(plVar2 + 6);
    if (uVar22 < 0x7ffffffffffffff8) {
      if (uVar22 < 0x17) {
        uStack_e0 = CONCAT17((char)uVar22,(undefined7)uStack_e0);
        pppppuVar15 = &ppppuStack_f0;
        if (uVar22 != 0) goto LAB_0152cd48;
      }
      else {
        uVar23 = (uVar22 & 0xfffffffffffffff8) + 8;
        if ((uVar22 | 7) != 0x17) {
          uVar23 = uVar22 | 7;
        }
        pppppuVar15 = (undefined8 *****)__Znwm(uVar23 + 1);
        uStack_e0 = uVar23 + 1 | 0x8000000000000000;
        ppppuStack_f0 = pppppuVar15;
        uStack_e8 = uVar22;
LAB_0152cd48:
        _memmove(pppppuVar15,plVar2 + 6,uVar22);
      }
      uVar23 = (ulong)iVar26;
      *(undefined1 *)((long)pppppuVar15 + uVar22) = 0;
      if (*(char *)((long)plVar13 + 0x17) < '\0') {
        __ZdlPv(*plVar13);
      }
      plVar13[1] = uStack_e8;
      *plVar13 = (long)ppppuStack_f0;
      plVar13[2] = uStack_e0;
      uVar22 = plVar13[1];
      if (-1 < (char)*(byte *)((long)plVar13 + 0x17)) {
        uVar22 = (ulong)*(byte *)((long)plVar13 + 0x17);
      }
      iVar26 = *(int *)((long)plVar2 + 0x24);
      lVar20 = (long)plVar2 + uVar23 + 0x31;
      uVar24 = _strlen(lVar20);
      if (0x7ffffffffffffff7 < uVar24) {
        func_0x00108f98(&ppppuStack_f0);
        goto LAB_0152d0e8;
      }
      if (uVar24 < 0x17) {
        uStack_e0 = CONCAT17((char)uVar24,(undefined7)uStack_e0);
        pppppuVar15 = &ppppuStack_f0;
        if (uVar24 != 0) goto LAB_0152ce0c;
      }
      else {
        uVar25 = (uVar24 & 0xfffffffffffffff8) + 8;
        if ((uVar24 | 7) != 0x17) {
          uVar25 = uVar24 | 7;
        }
        pppppuVar15 = (undefined8 *****)__Znwm(uVar25 + 1);
        uStack_e0 = uVar25 + 1 | 0x8000000000000000;
        ppppuStack_f0 = pppppuVar15;
        uStack_e8 = uVar24;
LAB_0152ce0c:
        _memmove(pppppuVar15,lVar20,uVar24);
      }
      *(undefined1 *)((long)pppppuVar15 + uVar24) = 0;
      if (*(char *)((long)plVar13 + 0x2f) < '\0') {
        __ZdlPv(plVar13[3]);
      }
      plVar13[4] = uStack_e8;
      plVar13[3] = (long)ppppuStack_f0;
      plVar13[5] = uStack_e0;
      lVar20 = uVar23 + (long)iVar26 + 0x32;
      uVar24 = plVar13[4];
      if (-1 < (char)*(byte *)((long)plVar13 + 0x2f)) {
        uVar24 = (ulong)*(byte *)((long)plVar13 + 0x2f);
      }
      lVar7 = plVar2[5];
      lVar12 = (long)plVar2 + lVar20;
      uVar25 = _strlen(lVar12);
      if (0x7ffffffffffffff7 < uVar25) {
        func_0x00108f98(&ppppuStack_f0);
        goto LAB_0152d0e8;
      }
      if (uVar25 < 0x17) {
        uStack_e0 = CONCAT17((char)uVar25,(undefined7)uStack_e0);
        pppppuVar15 = &ppppuStack_f0;
        if (uVar25 != 0) goto LAB_0152cedc;
      }
      else {
        uVar14 = (uVar25 & 0xfffffffffffffff8) + 8;
        if ((uVar25 | 7) != 0x17) {
          uVar14 = uVar25 | 7;
        }
        pppppuVar15 = (undefined8 *****)__Znwm(uVar14 + 1);
        uStack_e0 = uVar14 + 1 | 0x8000000000000000;
        ppppuStack_f0 = pppppuVar15;
        uStack_e8 = uVar25;
LAB_0152cedc:
        _memmove(pppppuVar15,lVar12,uVar25);
      }
      *(undefined1 *)((long)pppppuVar15 + uVar25) = 0;
      if (*(char *)((long)plVar13 + 0x47) < '\0') {
        __ZdlPv(plVar13[6]);
      }
      plVar13[7] = uStack_e8;
      plVar13[6] = (long)ppppuStack_f0;
      plVar13[8] = uStack_e0;
      lVar20 = lVar20 + (int)lVar7 + 1;
      uVar25 = plVar13[7];
      if (-1 < (char)*(byte *)((long)plVar13 + 0x47)) {
        uVar25 = (ulong)*(byte *)((long)plVar13 + 0x47);
      }
      iVar4 = *(int *)((long)plVar2 + 0x2c);
      lVar12 = (long)plVar2 + lVar20;
      uVar14 = _strlen(lVar12);
      if (0x7ffffffffffffff7 < uVar14) {
        func_0x00108f98(&ppppuStack_f0);
        goto LAB_0152d0e8;
      }
      if (uVar14 < 0x17) {
        uStack_e0 = CONCAT17((char)uVar14,(undefined7)uStack_e0);
        pppppuVar15 = &ppppuStack_f0;
        if (uVar14 != 0) goto LAB_0152cf9c;
      }
      else {
        uVar18 = (uVar14 & 0xfffffffffffffff8) + 8;
        if ((uVar14 | 7) != 0x17) {
          uVar18 = uVar14 | 7;
        }
        pppppuVar15 = (undefined8 *****)__Znwm(uVar18 + 1);
        uStack_e0 = uVar18 + 1 | 0x8000000000000000;
        ppppuStack_f0 = pppppuVar15;
        uStack_e8 = uVar14;
LAB_0152cf9c:
        _memmove(pppppuVar15,lVar12,uVar14);
      }
      *(undefined1 *)((long)pppppuVar15 + uVar14) = 0;
      if (*(char *)((long)plVar13 + 0x5f) < '\0') {
        __ZdlPv(plVar13[9]);
      }
      plVar13[10] = uStack_e8;
      plVar13[9] = (long)ppppuStack_f0;
      plVar13[0xb] = uStack_e0;
      uVar14 = plVar13[10];
      if (-1 < (char)*(byte *)((long)plVar13 + 0x5f)) {
        uVar14 = (ulong)*(byte *)((long)plVar13 + 0x5f);
      }
      uVar11 = 0x15;
      if (((uVar14 == (long)iVar4) && (uVar25 == (long)(int)lVar7)) &&
         ((uVar24 == (long)iVar26 &&
          (((uVar22 == uVar23 && (lVar12 = (long)iVar1 + 0x20, lVar20 + iVar4 + 1 == lVar12)) &&
           (lVar20 = plVar2[3], lVar12 < lVar20)))))) {
        lVar7 = *plVar17 + lVar12;
        lVar5 = (*plVar17 + lVar20) - lVar7;
        ppppuStack_f0 = (undefined8 *****)0x0;
        uStack_e8 = 0;
        uStack_e0 = 0;
        if (lVar5 < 0) {
          func_0x00108ee8(&ppppuStack_f0);
          goto LAB_0152d0e8;
        }
        lVar16 = __Znwm(lVar5);
        if (lVar20 != lVar12) {
          _memmove(lVar16,lVar7,lVar5);
        }
        lVar20 = plVar13[0xc];
        if (lVar20 != 0) {
          plVar13[0xd] = lVar20;
          __ZdlPv();
          plVar13[0xc] = 0;
          plVar13[0xd] = 0;
          plVar13[0xe] = 0;
        }
        uVar11 = 0;
        plVar13[0xc] = lVar16;
        plVar13[0xd] = lVar16 + lVar5;
        plVar13[0xe] = lVar16 + lVar5;
      }
      goto LAB_0152cc6c;
    }
  }
  func_0x00108f98(&ppppuStack_f0);
LAB_0152d0e8:
                    /* WARNING: Does not return */
  pcVar9 = (code *)SoftwareBreakpoint(1,0x152d0ec);
  (*pcVar9)();
}


/* __ZN5Proxy8Metadata11DeserializeERS0_RKNSt3__16vectorIhNS2_9allocatorIhEEEEj @ 0152cbd4 */

void __ZN5Proxy8Metadata11DeserializeERS0_RKNSt3__16vectorIhNS2_9allocatorIhEEEEj
               (long *param_1,long *param_2)

{
  int iVar1;
  long lVar2;
  ulong uVar3;
  long *plVar4;
  int iVar5;
  long lVar6;
  long lVar7;
  code *pcVar8;
  undefined8 uVar9;
  ulong uVar10;
  ulong uVar11;
  ulong uVar12;
  ulong uVar13;
  undefined8 ****ppppuVar14;
  long lVar15;
  long lVar16;
  ulong uVar17;
  int iVar18;
  undefined8 ***pppuStack_80;
  ulong uStack_78;
  undefined8 uStack_70;
  long lStack_68;

  lStack_68 = *(long *)PTR____stack_chk_guard_01d15188;
  plVar4 = (long *)*param_2;
  if ((((ulong)(param_2[1] - (long)plVar4) < 0x20) ||
      ((*plVar4 != 0x4f65727574706143 || plVar4[1] != 0x4d79786f7250656e) ||
       plVar4[2] != 0x61746164617465)) || ((ulong)(param_2[1] - (long)plVar4) < (ulong)plVar4[3])) {
    uVar9 = 0x15;
LAB_0152cc6c:
    if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_68) {
      return;
    }
    ___stack_chk_fail(uVar9);
  }
  else {
    iVar18 = (int)plVar4[4];
    iVar1 = iVar18 + (int)((ulong)plVar4[4] >> 0x20) +
            (int)plVar4[5] + (int)((ulong)plVar4[5] >> 0x20) + 0x14;
    uVar9 = 0x15;
    if ((iVar1 < 0) || ((long)(plVar4[3] - 0x30U) < (long)iVar1)) goto LAB_0152cc6c;
    uVar10 = _strlen(plVar4 + 6);
    if (uVar10 < 0x7ffffffffffffff8) {
      if (uVar10 < 0x17) {
        uStack_70 = CONCAT17((char)uVar10,(undefined7)uStack_70);
        ppppuVar14 = &pppuStack_80;
        if (uVar10 != 0) goto LAB_0152cd48;
      }
      else {
        uVar17 = (uVar10 & 0xfffffffffffffff8) + 8;
        if ((uVar10 | 7) != 0x17) {
          uVar17 = uVar10 | 7;
        }
        ppppuVar14 = (undefined8 ****)__Znwm(uVar17 + 1);
        uStack_70 = uVar17 + 1 | 0x8000000000000000;
        pppuStack_80 = ppppuVar14;
        uStack_78 = uVar10;
LAB_0152cd48:
        _memmove(ppppuVar14,plVar4 + 6,uVar10);
      }
      uVar17 = (ulong)iVar18;
      *(undefined1 *)((long)ppppuVar14 + uVar10) = 0;
      if (*(char *)((long)param_1 + 0x17) < '\0') {
        __ZdlPv(*param_1);
      }
      param_1[1] = uStack_78;
      *param_1 = (long)pppuStack_80;
      param_1[2] = uStack_70;
      uVar10 = param_1[1];
      if (-1 < (char)*(byte *)((long)param_1 + 0x17)) {
        uVar10 = (ulong)*(byte *)((long)param_1 + 0x17);
      }
      iVar18 = *(int *)((long)plVar4 + 0x24);
      lVar16 = (long)plVar4 + uVar17 + 0x31;
      uVar11 = _strlen(lVar16);
      if (0x7ffffffffffffff7 < uVar11) {
        func_0x00108f98(&pppuStack_80);
        goto LAB_0152d0e8;
      }
      if (uVar11 < 0x17) {
        uStack_70 = CONCAT17((char)uVar11,(undefined7)uStack_70);
        ppppuVar14 = &pppuStack_80;
        if (uVar11 != 0) goto LAB_0152ce0c;
      }
      else {
        uVar12 = (uVar11 & 0xfffffffffffffff8) + 8;
        if ((uVar11 | 7) != 0x17) {
          uVar12 = uVar11 | 7;
        }
        ppppuVar14 = (undefined8 ****)__Znwm(uVar12 + 1);
        uStack_70 = uVar12 + 1 | 0x8000000000000000;
        pppuStack_80 = ppppuVar14;
        uStack_78 = uVar11;
LAB_0152ce0c:
        _memmove(ppppuVar14,lVar16,uVar11);
      }
      *(undefined1 *)((long)ppppuVar14 + uVar11) = 0;
      if (*(char *)((long)param_1 + 0x2f) < '\0') {
        __ZdlPv(param_1[3]);
      }
      param_1[4] = uStack_78;
      param_1[3] = (long)pppuStack_80;
      param_1[5] = uStack_70;
      lVar16 = uVar17 + (long)iVar18 + 0x32;
      uVar11 = param_1[4];
      if (-1 < (char)*(byte *)((long)param_1 + 0x2f)) {
        uVar11 = (ulong)*(byte *)((long)param_1 + 0x2f);
      }
      lVar7 = plVar4[5];
      lVar2 = (long)plVar4 + lVar16;
      uVar12 = _strlen(lVar2);
      if (0x7ffffffffffffff7 < uVar12) {
        func_0x00108f98(&pppuStack_80);
        goto LAB_0152d0e8;
      }
      if (uVar12 < 0x17) {
        uStack_70 = CONCAT17((char)uVar12,(undefined7)uStack_70);
        ppppuVar14 = &pppuStack_80;
        if (uVar12 != 0) goto LAB_0152cedc;
      }
      else {
        uVar13 = (uVar12 & 0xfffffffffffffff8) + 8;
        if ((uVar12 | 7) != 0x17) {
          uVar13 = uVar12 | 7;
        }
        ppppuVar14 = (undefined8 ****)__Znwm(uVar13 + 1);
        uStack_70 = uVar13 + 1 | 0x8000000000000000;
        pppuStack_80 = ppppuVar14;
        uStack_78 = uVar12;
LAB_0152cedc:
        _memmove(ppppuVar14,lVar2,uVar12);
      }
      *(undefined1 *)((long)ppppuVar14 + uVar12) = 0;
      if (*(char *)((long)param_1 + 0x47) < '\0') {
        __ZdlPv(param_1[6]);
      }
      param_1[7] = uStack_78;
      param_1[6] = (long)pppuStack_80;
      param_1[8] = uStack_70;
      lVar16 = lVar16 + (int)lVar7 + 1;
      uVar12 = param_1[7];
      if (-1 < (char)*(byte *)((long)param_1 + 0x47)) {
        uVar12 = (ulong)*(byte *)((long)param_1 + 0x47);
      }
      iVar5 = *(int *)((long)plVar4 + 0x2c);
      lVar2 = (long)plVar4 + lVar16;
      uVar13 = _strlen(lVar2);
      if (0x7ffffffffffffff7 < uVar13) {
        func_0x00108f98(&pppuStack_80);
        goto LAB_0152d0e8;
      }
      if (uVar13 < 0x17) {
        uStack_70 = CONCAT17((char)uVar13,(undefined7)uStack_70);
        ppppuVar14 = &pppuStack_80;
        if (uVar13 != 0) goto LAB_0152cf9c;
      }
      else {
        uVar3 = (uVar13 & 0xfffffffffffffff8) + 8;
        if ((uVar13 | 7) != 0x17) {
          uVar3 = uVar13 | 7;
        }
        ppppuVar14 = (undefined8 ****)__Znwm(uVar3 + 1);
        uStack_70 = uVar3 + 1 | 0x8000000000000000;
        pppuStack_80 = ppppuVar14;
        uStack_78 = uVar13;
LAB_0152cf9c:
        _memmove(ppppuVar14,lVar2,uVar13);
      }
      *(undefined1 *)((long)ppppuVar14 + uVar13) = 0;
      if (*(char *)((long)param_1 + 0x5f) < '\0') {
        __ZdlPv(param_1[9]);
      }
      param_1[10] = uStack_78;
      param_1[9] = (long)pppuStack_80;
      param_1[0xb] = uStack_70;
      uVar13 = param_1[10];
      if (-1 < (char)*(byte *)((long)param_1 + 0x5f)) {
        uVar13 = (ulong)*(byte *)((long)param_1 + 0x5f);
      }
      uVar9 = 0x15;
      if (((uVar13 == (long)iVar5) && (uVar12 == (long)(int)lVar7)) &&
         ((uVar11 == (long)iVar18 &&
          (((uVar10 == uVar17 && (lVar2 = (long)iVar1 + 0x20, lVar16 + iVar5 + 1 == lVar2)) &&
           (lVar16 = plVar4[3], lVar2 < lVar16)))))) {
        lVar7 = *param_2 + lVar2;
        lVar6 = (*param_2 + lVar16) - lVar7;
        pppuStack_80 = (undefined8 ****)0x0;
        uStack_78 = 0;
        uStack_70 = 0;
        if (lVar6 < 0) {
          func_0x00108ee8(&pppuStack_80);
          goto LAB_0152d0e8;
        }
        lVar15 = __Znwm(lVar6);
        if (lVar16 != lVar2) {
          _memmove(lVar15,lVar7,lVar6);
        }
        lVar16 = param_1[0xc];
        if (lVar16 != 0) {
          param_1[0xd] = lVar16;
          __ZdlPv();
          param_1[0xc] = 0;
          param_1[0xd] = 0;
          param_1[0xe] = 0;
        }
        uVar9 = 0;
        param_1[0xc] = lVar15;
        param_1[0xd] = lVar15 + lVar6;
        param_1[0xe] = lVar15 + lVar6;
      }
      goto LAB_0152cc6c;
    }
  }
  func_0x00108f98(&pppuStack_80);
LAB_0152d0e8:
                    /* WARNING: Does not return */
  pcVar8 = (code *)SoftwareBreakpoint(1,0x152d0ec);
  (*pcVar8)();
}


/* __ZNK5Proxy8Metadata15DeserializeTagsEv @ 0152d114 */

/* WARNING: Possible PIC construction at 0x00311074: Changing call to branch */
/* WARNING: Possible PIC construction at 0x00311140: Changing call to branch */
/* WARNING: Possible PIC construction at 0x00310f58: Changing call to branch */
/* WARNING: Removing unreachable block (ram,0x00311144) */
/* WARNING: Removing unreachable block (ram,0x0031114c) */
/* WARNING: Removing unreachable block (ram,0x00311078) */
/* WARNING: Removing unreachable block (ram,0x00311128) */
/* WARNING: Removing unreachable block (ram,0x00311094) */
/* WARNING: Removing unreachable block (ram,0x003110b8) */
/* WARNING: Removing unreachable block (ram,0x003110c4) */
/* WARNING: Removing unreachable block (ram,0x003111b0) */
/* WARNING: Removing unreachable block (ram,0x003111bc) */
/* WARNING: Removing unreachable block (ram,0x003111c8) */
/* WARNING: Removing unreachable block (ram,0x003111d4) */
/* WARNING: Removing unreachable block (ram,0x003110d0) */
/* WARNING: Removing unreachable block (ram,0x003110a0) */
/* WARNING: Removing unreachable block (ram,0x003110ac) */
/* WARNING: Removing unreachable block (ram,0x0031112c) */
/* WARNING: Removing unreachable block (ram,0x0031115c) */
/* WARNING: Removing unreachable block (ram,0x00311168) */
/* WARNING: Removing unreachable block (ram,0x00311138) */
/* WARNING: Removing unreachable block (ram,0x00310f5c) */
/* WARNING: Type propagation algorithm not settling */

undefined8 ******
__ZNK5Proxy8Metadata15DeserializeTagsEv(long param_1,undefined8 param_2,byte *param_3)

{
  long lVar1;
  uint *puVar2;
  ulong uVar3;
  uint uVar4;
  uint uVar5;
  int *piVar6;
  uint uVar7;
  uint uVar8;
  byte bVar9;
  short sVar10;
  code *pcVar11;
  bool bVar12;
  ulong uVar13;
  long *plVar14;
  undefined8 *puVar15;
  undefined8 ******ppppppuVar16;
  undefined8 ******ppppppuVar17;
  short *psVar18;
  undefined8 *******pppppppuVar19;
  undefined4 uVar20;
  undefined4 *puVar21;
  undefined8 *******extraout_x8;
  ulong uVar22;
  uint *puVar23;
  undefined8 *******unaff_x23;
  undefined8 uVar24;
  uint uVar25;
  uint uVar26;
  uint uVar27;
  uint uVar28;
  undefined1 auVar29 [16];
  undefined1 auVar30 [16];
  long lStack_238;
  long lStack_230;
  long lStack_220;
  long lStack_218;
  undefined8 *******pppppppuStack_208;
  ulong uStack_200;
  undefined8 uStack_1f8;
  undefined8 *******pppppppuStack_1f0;
  ulong uStack_1e8;
  undefined8 uStack_1e0;
  long alStack_1d8 [3];
  uint *puStack_1c0;
  long lStack_1b8;
  undefined8 *****pppppuStack_140;
  undefined8 *****pppppuStack_138;
  undefined8 *****pppppuStack_130;
  long lStack_128;
  ulong uStack_120;
  undefined8 *******pppppppuStack_118;
  undefined4 *puStack_110;
  ulong uStack_108;
  undefined8 *puStack_100;
  ulong uStack_f8;
  undefined1 **ppuStack_f0;
  undefined8 uStack_e8;
  undefined8 *******pppppppuStack_d8;
  ulong uStack_d0;
  undefined8 uStack_c8;
  undefined8 *******pppppppuStack_c0;
  ulong uStack_b8;
  long lStack_b0;
  byte bStack_9d;
  undefined4 uStack_9c;
  long lStack_98;
  undefined1 *puStack_30;
  undefined8 uStack_28;
  int *piStack_20;
  long lStack_18;

  piVar6 = *(int **)(param_1 + 0x60);
  auVar29._8_8_ = *(long *)(param_1 + 0x68);
  auVar29._0_8_ = &piStack_20;
  lStack_18 = *(long *)PTR____stack_chk_guard_01d15188;
  if ((*piVar6 == -0x35014542) &&
     ((long)piVar6 + (ulong)(uint)piVar6[1] == *(long *)(param_1 + 0x68))) {
    piStack_20 = piVar6 + 3;
    uVar24 = 0x310f5c;
  }
  else {
    if (*(long *)PTR____stack_chk_guard_01d15188 == *(long *)PTR____stack_chk_guard_01d15188) {
      return (undefined8 ******)0x0;
    }
    uVar24 = 0x310f78;
    auVar29 = ___stack_chk_fail(0);
  }
  uVar13 = auVar29._8_8_;
  puStack_30 = &stack0xfffffffffffffff0;
  uStack_28 = uVar24;
  lStack_98 = *(long *)PTR____stack_chk_guard_01d15188;
  puVar21 = (undefined4 *)*auVar29._0_8_;
  uStack_9c = *puVar21;
  uVar4 = puVar21[1];
  uVar5 = puVar21[3];
  uVar22 = (ulong)uVar5;
  bStack_9d = (byte)(uVar4 >> 0x1f);
  puVar21 = puVar21 + 4;
  pppppppuStack_c0 = (undefined8 *******)0x0;
  uStack_b8 = 0;
  lStack_b0 = 0;
  if ((int)uVar5 < 1) {
LAB_00311064:
    pppppppuVar19 = &pppppppuStack_d8;
    auVar30._8_8_ = &uStack_9c;
    auVar30._0_8_ = &pppppppuStack_c0;
    param_3 = &bStack_9d;
    uVar24 = 0x311078;
  }
  else {
    if ((long)puVar21 + uVar22 <= uVar13) {
      if (uVar5 < 0x17) {
        uStack_c8 = CONCAT17((char)uVar5,(undefined7)uStack_c8);
        unaff_x23 = &pppppppuStack_d8;
      }
      else {
        uVar3 = (uVar22 & 0xfffffff8) + 8;
        if ((uVar22 | 7) != 0x17) {
          uVar3 = uVar22 | 7;
        }
        unaff_x23 = (undefined8 *******)__Znwm(uVar3 + 1);
        uStack_c8 = uVar3 + 0x8000000000000001;
        pppppppuStack_d8 = unaff_x23;
        uStack_d0 = uVar22;
      }
      _memmove(unaff_x23,puVar21,uVar22);
      *(undefined1 *)((long)unaff_x23 + uVar22) = 0;
      uStack_b8 = uStack_d0;
      pppppppuStack_c0 = pppppppuStack_d8;
      lStack_b0 = uStack_c8;
      goto LAB_00311064;
    }
    if (*(long *)PTR____stack_chk_guard_01d15188 == *(long *)PTR____stack_chk_guard_01d15188) {
      return (undefined8 ******)0x0;
    }
    uVar13 = ___stack_chk_fail();
    while (-1 < lStack_b0) {
      plVar14 = (long *)__Unwind_Resume(uVar13);
      (**(code **)(*plVar14 + 8))();
    }
    __ZdlPv(pppppppuStack_c0);
    uVar24 = 0x311238;
    auVar30 = __Unwind_Resume(uVar13);
    pppppppuVar19 = extraout_x8;
  }
  puVar15 = auVar30._0_8_;
  lStack_128 = *(long *)PTR____stack_chk_guard_01d15188;
  uStack_120 = (ulong)uVar4;
  pppppppuStack_118 = unaff_x23;
  puStack_110 = puVar21;
  uStack_108 = uVar22;
  puStack_100 = auVar29._0_8_;
  uStack_f8 = uVar13;
  ppuStack_f0 = &puStack_30;
  uStack_e8 = uVar24;
  ppppppuVar16 = (undefined8 ******)__Znwm(0xa0);
  if (*(char *)((long)puVar15 + 0x17) < '\0') {
    func_0x00109e84(&pppppuStack_140,*puVar15,puVar15[1]);
  }
  else {
    pppppuStack_138 = (undefined8 *****)puVar15[1];
    pppppuStack_140 = (undefined8 *****)*puVar15;
    pppppuStack_130 = (undefined8 *****)puVar15[2];
  }
  uVar20 = *auVar30._8_8_;
  bVar9 = *param_3;
  *ppppppuVar16 = (undefined8 *****)&PTR___ZN13CTagDirectoryD1Ev_01ddcc20;
  ppppppuVar16[1] = (undefined8 *****)0x0;
  *(undefined4 *)(ppppppuVar16 + 2) = uVar20;
  ppppppuVar17 = ppppppuVar16 + 3;
  if ((long)pppppuStack_130 < 0) {
    ppppppuVar17 = (undefined8 ******)func_0x00109e84(ppppppuVar17,pppppuStack_140,pppppuStack_138);
    bVar12 = (long)pppppuStack_130 < 0;
  }
  else {
    bVar12 = false;
    ppppppuVar16[4] = pppppuStack_138;
    *ppppppuVar17 = pppppuStack_140;
    ppppppuVar16[5] = pppppuStack_130;
  }
  *(byte *)(ppppppuVar16 + 6) = bVar9;
  ppppppuVar16[7] = (undefined8 *****)0x0;
  ppppppuVar16[8] = (undefined8 *****)0x0;
  ppppppuVar16[0xb] = (undefined8 *****)0x0;
  ppppppuVar16[0xc] = (undefined8 *****)0x0;
  ppppppuVar16[0xd] = (undefined8 *****)0x0;
  ppppppuVar16[9] = (undefined8 *****)0x0;
  ppppppuVar16[10] = ppppppuVar16 + 0xb;
  ppppppuVar16[0xe] = (undefined8 *****)0x0;
  ppppppuVar16[0xf] = (undefined8 *****)0x0;
  ppppppuVar16[0x12] = (undefined8 *****)0x0;
  ppppppuVar16[0x13] = (undefined8 *****)0x0;
  ppppppuVar16[0x11] = (undefined8 *****)0x0;
  ppppppuVar16[0x10] = ppppppuVar16 + 0x11;
  *pppppppuVar19 = ppppppuVar16;
  if (bVar12) {
    ppppppuVar17 = (undefined8 ******)__ZdlPv(pppppuStack_140);
  }
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_128) {
    return ppppppuVar17;
  }
  uVar24 = ___stack_chk_fail();
  if ((long)pppppuStack_130 < 0) {
    __ZdlPv(pppppuStack_140);
    __ZdlPv(ppppppuVar16);
    uVar24 = __Unwind_Resume(uVar24);
  }
  __ZdlPv(ppppppuVar16);
  auVar29 = __Unwind_Resume(uVar24);
  psVar18 = auVar29._0_8_;
  lStack_1b8 = *(long *)PTR____stack_chk_guard_01d15188;
  if (auVar29._8_4_ < 10) {
    puVar21 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar21 = 0xffffd508;
    ___cxa_throw(puVar21,&__ZTI15FilmCurveErrors,0);
LAB_003118fc:
    puVar21 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar21 = 0xffffd505;
    ___cxa_throw(puVar21,&__ZTI15FilmCurveErrors,0);
LAB_0031191c:
    puVar21 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar21 = 0xffffd506;
    ___cxa_throw(puVar21,&__ZTI15FilmCurveErrors,0);
LAB_0031193c:
    puVar21 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar21 = 0xffffd505;
    ___cxa_throw(puVar21,&__ZTI15FilmCurveErrors,0);
    goto LAB_00311a8c;
  }
  sVar10 = *psVar18;
  if (sVar10 == 0x4949 || sVar10 == 0x4d4d) {
    uVar13 = auVar29._8_8_ & 0xffffffff;
    if (uVar13 - 2 < 4) goto LAB_003118fc;
    uVar5 = *(uint *)(psVar18 + 1);
    puStack_1c0 = (uint *)(psVar18 + 3);
    uVar4 = (uVar5 & 0xff00ff00) >> 8 | (uVar5 & 0xff00ff) << 8;
    uVar4 = uVar4 >> 0x10 | uVar4 << 0x10;
    if (sVar10 != 0x4d4d) {
      uVar4 = uVar5;
    }
    if (uVar4 < 2) goto LAB_0031191c;
    lVar1 = (long)psVar18 + uVar13;
    __ZN10CaptureOne10CameraCore12_GLOBAL__N_124DeserialiseFilmCurveDataINSt3__16vectorINS3_5tupleIJddEEENS3_9allocatorIS6_EEEEEET_RPKhSC_b
              (alStack_1d8,&puStack_1c0,lVar1,sVar10 == 0x4d4d);
    if ((ulong)(lVar1 - (long)puStack_1c0) < 4) goto LAB_0031193c;
    uVar7 = *puStack_1c0;
    uVar5 = (uVar7 & 0xff00ff00) >> 8 | (uVar7 & 0xff00ff) << 8;
    uVar5 = uVar5 >> 0x10 | uVar5 << 0x10;
    if (sVar10 != 0x4d4d) {
      uVar5 = uVar7;
    }
    if (3 < (lVar1 - (long)puStack_1c0) - 4U) {
      uVar27 = puStack_1c0[1];
      puVar2 = puStack_1c0 + 2;
      uVar7 = (uVar27 & 0xff00ff00) >> 8 | (uVar27 & 0xff00ff) << 8;
      uVar7 = uVar7 >> 0x10 | uVar7 << 0x10;
      if (sVar10 != 0x4d4d) {
        uVar7 = uVar27;
      }
      uVar13 = (ulong)uVar7;
      puStack_1c0 = puVar2;
      if ((long)uVar13 <= lVar1 - (long)puVar2) {
        if (uVar7 < 0x17) {
          uStack_1e0 = CONCAT17((char)uVar7,(undefined7)uStack_1e0);
          pppppppuVar19 = &pppppppuStack_1f0;
          if (uVar7 != 0) goto LAB_003114e0;
        }
        else {
          uVar22 = (uVar13 & 0xfffffff8) + 8;
          if ((uVar13 | 7) != 0x17) {
            uVar22 = uVar13 | 7;
          }
          pppppppuVar19 = (undefined8 *******)__Znwm(uVar22 + 1);
          uStack_1e0 = uVar22 + 1 | 0x8000000000000000;
          pppppppuStack_1f0 = pppppppuVar19;
          uStack_1e8 = uVar13;
LAB_003114e0:
          _memmove(pppppppuVar19,puVar2,uVar13);
        }
        *(undefined1 *)((long)pppppppuVar19 + uVar13) = 0;
        puVar2 = (uint *)((long)puStack_1c0 + uVar13);
        if (3 < (ulong)(lVar1 - (long)puVar2)) {
          puVar23 = puVar2 + 1;
          uVar27 = *puVar2;
          uVar7 = (uVar27 & 0xff00ff00) >> 8 | (uVar27 & 0xff00ff) << 8;
          uVar7 = uVar7 >> 0x10 | uVar7 << 0x10;
          if (sVar10 != 0x4d4d) {
            uVar7 = uVar27;
          }
          uVar13 = (ulong)uVar7;
          puStack_1c0 = puVar23;
          if ((long)uVar13 <= lVar1 - (long)puVar23) {
            if (0x16 < uVar7) {
              uVar22 = (uVar13 & 0xfffffff8) + 8;
              if ((uVar13 | 7) != 0x17) {
                uVar22 = uVar13 | 7;
              }
              pppppppuVar19 = (undefined8 *******)__Znwm(uVar22 + 1);
              uStack_1f8 = uVar22 + 1 | 0x8000000000000000;
              pppppppuStack_208 = pppppppuVar19;
              uStack_200 = uVar13;
LAB_00311650:
              _memmove(pppppppuVar19,puVar23,uVar13);
              *(undefined1 *)((long)pppppppuVar19 + uVar13) = 0;
              if (uVar4 != 2) goto LAB_0031154c;
LAB_0031166c:
              ppppppuVar16 = (undefined8 ******)func_0x01556328(0x78);
              func_0x01553c84(ppppppuVar16,&pppppppuStack_208,&pppppppuStack_1f0,alStack_1d8,uVar5,
                              &UNK_0003020c,0x42);
              goto LAB_00311698;
            }
            uStack_1f8 = CONCAT17((char)uVar7,(undefined7)uStack_1f8);
            pppppppuVar19 = &pppppppuStack_208;
            if (uVar7 != 0) goto LAB_00311650;
                    /* WARNING: Ignoring partial resolution of indirect */
            pppppppuStack_208._0_1_ = 0;
            if (uVar4 == 2) goto LAB_0031166c;
LAB_0031154c:
            if (uVar4 != 3) {
              puVar2 = (uint *)((long)puStack_1c0 + uVar13);
              uVar13 = lVar1 - (long)puVar2;
              if (uVar13 < 4) {
                puVar21 = (undefined4 *)___cxa_allocate_exception(4);
                *puVar21 = 0xffffd505;
                ___cxa_throw(puVar21,&__ZTI15FilmCurveErrors,0);
                goto LAB_00311a8c;
              }
              puStack_1c0 = puVar2 + 1;
              uVar27 = *puVar2;
              uVar7 = (uVar27 & 0xff00ff00) >> 8 | (uVar27 & 0xff00ff) << 8;
              uVar7 = uVar7 >> 0x10 | uVar7 << 0x10;
              if (sVar10 != 0x4d4d) {
                uVar7 = uVar27;
              }
              if ((ulong)(lVar1 - (long)puStack_1c0) < 4) {
                puVar21 = (undefined4 *)___cxa_allocate_exception(4);
                *puVar21 = 0xffffd505;
                ___cxa_throw(puVar21,&__ZTI15FilmCurveErrors,0);
                goto LAB_00311a8c;
              }
              uVar25 = puVar2[1];
              uVar27 = (uVar25 & 0xff00ff00) >> 8 | (uVar25 & 0xff00ff) << 8;
              uVar27 = uVar27 >> 0x10 | uVar27 << 0x10;
              if (sVar10 != 0x4d4d) {
                uVar27 = uVar25;
              }
              if (uVar13 - 8 < 4) {
                puVar21 = (undefined4 *)___cxa_allocate_exception(4);
                *puVar21 = 0xffffd505;
                ___cxa_throw(puVar21,&__ZTI15FilmCurveErrors,0);
                goto LAB_00311a8c;
              }
              uVar28 = puVar2[2];
              uVar25 = (uVar28 & 0xff00ff00) >> 8 | (uVar28 & 0xff00ff) << 8;
              uVar25 = uVar25 >> 0x10 | uVar25 << 0x10;
              if (sVar10 != 0x4d4d) {
                uVar25 = uVar28;
              }
              if (uVar13 - 0xc < 4) {
                puVar21 = (undefined4 *)___cxa_allocate_exception(4);
                *puVar21 = 0xffffd505;
                ___cxa_throw(puVar21,&__ZTI15FilmCurveErrors,0);
                goto LAB_00311a8c;
              }
              uVar8 = puVar2[3];
              uVar28 = (uVar8 & 0xff00ff00) >> 8 | (uVar8 & 0xff00ff) << 8;
              uVar28 = uVar28 >> 0x10 | uVar28 << 0x10;
              if (sVar10 != 0x4d4d) {
                uVar28 = uVar8;
              }
              if (uVar4 == 4) {
                ppppppuVar16 = (undefined8 ******)func_0x01556328(0x78);
                func_0x01553d14(uVar27,ppppppuVar16,&pppppppuStack_208,&pppppppuStack_1f0,
                                alStack_1d8,uVar5,uVar25,uVar28,uVar7);
              }
              else {
                if ((ulong)(lVar1 - (long)(puVar2 + 4)) < 4) {
                  puVar21 = (undefined4 *)___cxa_allocate_exception(4);
                  *puVar21 = 0xffffd505;
                  ___cxa_throw(puVar21,&__ZTI15FilmCurveErrors,0);
                  goto LAB_00311a8c;
                }
                uVar26 = puVar2[4];
                puStack_1c0 = puVar2 + 5;
                uVar8 = (uVar26 & 0xff00ff00) >> 8 | (uVar26 & 0xff00ff) << 8;
                uVar8 = uVar8 >> 0x10 | uVar8 << 0x10;
                if (sVar10 != 0x4d4d) {
                  uVar8 = uVar26;
                }
                if (uVar4 == 5) {
                  ppppppuVar16 = (undefined8 ******)func_0x01556328(0x78);
                  func_0x01553da0(uVar27,ppppppuVar16,uVar8,&pppppppuStack_208,&pppppppuStack_1f0,
                                  alStack_1d8,uVar5,uVar25,uVar28,uVar7);
                }
                else {
                  __ZN10CaptureOne10CameraCore12_GLOBAL__N_124DeserialiseFilmCurveDataINSt3__16vectorINS3_5tupleIJddEEENS3_9allocatorIS6_EEEEEET_RPKhSC_b
                            (&lStack_220,&puStack_1c0,lVar1,sVar10 == 0x4d4d);
                  __ZN10CaptureOne10CameraCore12_GLOBAL__N_124DeserialiseFilmCurveDataINSt3__16vectorINS3_5tupleIJddEEENS3_9allocatorIS6_EEEEEET_RPKhSC_b
                            (&lStack_238,&puStack_1c0,lVar1,sVar10 == 0x4d4d);
                  if (uVar4 != 6) {
                    if ((ulong)(lVar1 - (long)puStack_1c0) < 4) {
                      puVar21 = (undefined4 *)___cxa_allocate_exception(4);
                      uVar20 = 0xffffd505;
                    }
                    else {
                      uVar26 = *puStack_1c0;
                      uVar28 = (uVar26 & 0xff00ff00) >> 8 | (uVar26 & 0xff00ff) << 8;
                      uVar28 = uVar28 >> 0x10 | uVar28 << 0x10;
                      if (sVar10 != 0x4d4d) {
                        uVar28 = uVar26;
                      }
                      if (uVar4 == 7) {
                        ppppppuVar16 = (undefined8 ******)func_0x01556328(0x78);
                        func_0x01553e84(uVar27,uVar28,ppppppuVar16,uVar8,&pppppppuStack_208,
                                        &pppppppuStack_1f0,alStack_1d8,&lStack_220,&lStack_238,uVar5
                                        ,uVar25,uVar7);
                        goto LAB_00311870;
                      }
                      puVar21 = (undefined4 *)___cxa_allocate_exception(4);
                      uVar20 = 0xffffd506;
                    }
                    *puVar21 = uVar20;
                    ___cxa_throw(puVar21,&__ZTI15FilmCurveErrors,0);
                    goto LAB_00311a8c;
                  }
                  ppppppuVar16 = (undefined8 ******)func_0x01556328(0x78);
                  func_0x01553e30(uVar27,ppppppuVar16,uVar8,&pppppppuStack_208,&pppppppuStack_1f0,
                                  alStack_1d8,&lStack_220,&lStack_238,uVar5,uVar25,uVar7);
LAB_00311870:
                  if (lStack_238 != 0) {
                    lStack_230 = lStack_238;
                    __ZdlPv();
                  }
                  if (lStack_220 != 0) {
                    lStack_218 = lStack_220;
                    __ZdlPv();
                  }
                }
              }
LAB_00311698:
              if ((long)uStack_1f8 < 0) {
                __ZdlPv(pppppppuStack_208);
              }
              if ((long)uStack_1e0 < 0) {
                __ZdlPv(pppppppuStack_1f0);
              }
              if (alStack_1d8[0] != 0) {
                __ZdlPv();
              }
              if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_1b8) {
                return ppppppuVar16;
              }
              ___stack_chk_fail();
              goto LAB_00311964;
            }
            goto LAB_00311984;
          }
        }
        puVar21 = (undefined4 *)___cxa_allocate_exception(4);
        *puVar21 = 0xffffd505;
        ___cxa_throw(puVar21,&__ZTI15FilmCurveErrors,0);
        goto LAB_00311a8c;
      }
    }
    puVar21 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar21 = 0xffffd505;
    ___cxa_throw(puVar21,&__ZTI15FilmCurveErrors,0);
  }
  else {
LAB_00311964:
    puVar21 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar21 = 0xffffd507;
    ___cxa_throw(puVar21,&__ZTI15FilmCurveErrors,0);
LAB_00311984:
    puVar21 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar21 = 0xffffd506;
    ___cxa_throw(puVar21,&__ZTI15FilmCurveErrors,0);
  }
LAB_00311a8c:
                    /* WARNING: Does not return */
  pcVar11 = (code *)SoftwareBreakpoint(1,0x311a90);
  (*pcVar11)();
}


/* __ZN5Proxy8MetadataD1Ev @ 0152d82c */

undefined8 * __ZN5Proxy8MetadataD1Ev(undefined8 *param_1)

{
  char cVar1;

  if (param_1[0xc] != 0) {
    param_1[0xd] = param_1[0xc];
    __ZdlPv();
  }
  if (*(char *)((long)param_1 + 0x5f) < '\0') {
    __ZdlPv(param_1[9]);
    cVar1 = *(char *)((long)param_1 + 0x47);
  }
  else {
    cVar1 = *(char *)((long)param_1 + 0x47);
  }
  if (cVar1 < '\0') {
    __ZdlPv(param_1[6]);
    cVar1 = *(char *)((long)param_1 + 0x2f);
  }
  else {
    cVar1 = *(char *)((long)param_1 + 0x2f);
  }
  if (cVar1 < '\0') {
    __ZdlPv(param_1[3]);
    cVar1 = *(char *)((long)param_1 + 0x17);
  }
  else {
    cVar1 = *(char *)((long)param_1 + 0x17);
  }
  if (cVar1 < '\0') {
    __ZdlPv(*param_1);
    return param_1;
  }
  return param_1;
}


/* __ZN5Proxy4OpenERKNSt3__112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEE @ 0152da24 */

/* WARNING: Possible PIC construction at 0x0152dcf0: Changing call to branch */
/* WARNING: Removing unreachable block (ram,0x0152dcf4) */
/* WARNING: Removing unreachable block (ram,0x0152dd0c) */
/* WARNING: Removing unreachable block (ram,0x0152dd18) */
/* WARNING: Removing unreachable block (ram,0x0152dd38) */
/* WARNING: Removing unreachable block (ram,0x0152dd54) */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __ZN5Proxy4OpenERKNSt3__112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEE
               (long *param_1,undefined8 *param_2)

{
  undefined8 *puVar1;
  undefined8 *puVar2;
  undefined1 *puVar3;
  undefined8 *puVar4;
  char cVar5;
  undefined1 auVar6 [16];
  code *pcVar7;
  int iVar8;
  int *piVar9;
  undefined8 *puVar10;
  ulong uVar11;
  long *plVar12;
  long *plVar13;
  undefined8 *puVar14;
  long lVar15;
  undefined8 uVar16;
  undefined8 *puVar17;
  long lVar18;
  undefined8 *puVar19;
  long *unaff_x19;
  undefined8 *unaff_x20;
  long *plVar20;
  long unaff_x21;
  long unaff_x22;
  undefined8 unaff_x23;
  ulong uVar21;
  undefined8 unaff_x24;
  long *plVar22;
  undefined8 unaff_x25;
  undefined8 *unaff_x26;
  undefined8 unaff_x27;
  undefined8 unaff_x28;
  undefined1 *unaff_x29;
  undefined8 unaff_x30;
  undefined8 uVar23;
  undefined1 auVar24 [16];
  undefined1 auVar25 [16];
  char acStack_620 [1440];
  undefined8 uStack_80;
  undefined8 uStack_78;
  long lStack_70;
  long lStack_68;
  long *plStack_60;
  long lStack_58;

  auVar24._8_8_ = unaff_x24;
  auVar24._0_8_ = unaff_x23;
  auVar25._8_8_ = param_2;
  auVar25._0_8_ = param_1;
  auVar6._8_8_ = param_2;
  auVar6._0_8_ = param_1;
  puVar3 = &stack0xfffffffffffffff0;
  lStack_58 = *(long *)PTR____stack_chk_guard_01d15188;
  if ((int)fRam0000000002011b38 == 0) {
    func_0x010fa3cc(&lStack_68);
    if (lStack_68 == 0) {
      uVar16 = ___cxa_allocate_exception(0x10);
      __ZNSt13runtime_errorC1EPKc(uVar16,"missing global ImageCore instance");
      ___cxa_throw(uVar16,PTR___ZTISt13runtime_error_01d14f30,PTR___ZNSt13runtime_errorD1Ev_01d14a18
                  );
                    /* WARNING: Does not return */
      pcVar7 = (code *)SoftwareBreakpoint(1,0x152dc54);
      (*pcVar7)();
    }
    unaff_x21 = *(long *)(*(long *)(lStack_68 + 0x10) + 0x418);
    if (__DEBUG_BYPASS_CACHE < 1) {
      lVar18 = unaff_x21 + 0x20;
      __ZNSt3__115recursive_mutex4lockEv(lVar18);
      lVar15 = func_0x0116e43c(unaff_x21,param_2);
      if (lVar15 == 0) {
        __ZNSt3__115recursive_mutex6unlockEv(lVar18);
        goto LAB_0152dad0;
      }
      unaff_x26 = *(undefined8 **)(lVar15 + 0x20);
      __ZNSt3__115recursive_mutex6unlockEv(lVar18);
      if ((unaff_x26 == (undefined8 *)0x0) ||
         ((undefined **)*unaff_x26 != &PTR____cxa_deleted_virtual_01ffccb8)) goto LAB_0152dad0;
    }
    else {
LAB_0152dad0:
      unaff_x26 = (undefined8 *)0x0;
    }
    uStack_80 = 0;
    uStack_78 = 0;
    lStack_70 = 0;
    uVar11 = param_2[1];
    puVar10 = (undefined8 *)*param_2;
    if (-1 < (char)*(byte *)((long)param_2 + 0x17)) {
      uVar11 = (ulong)*(byte *)((long)param_2 + 0x17);
      puVar10 = param_2;
    }
    func_0x0110a298(&uStack_80,puVar10,(long)puVar10 + uVar11);
    auVar24 = __ZNSt3__14__fs10filesystem17__last_write_timeERKNS1_4pathEPNS_10error_codeE
                        (&uStack_80,0);
    if (lStack_70 < 0) {
      __ZdlPv(uStack_80);
    }
    uStack_80 = 0;
    uStack_78 = 0;
    lStack_70 = 0;
    uVar11 = param_2[1];
    puVar10 = (undefined8 *)*param_2;
    if (-1 < (char)*(byte *)((long)param_2 + 0x17)) {
      uVar11 = (ulong)*(byte *)((long)param_2 + 0x17);
      puVar10 = param_2;
    }
    func_0x0110a298(&uStack_80,puVar10,(long)puVar10 + uVar11);
    unaff_x22 = __ZNSt3__14__fs10filesystem11__file_sizeERKNS1_4pathEPNS_10error_codeE(&uStack_80,0)
    ;
    if (lStack_70 < 0) {
      __ZdlPv(uStack_80);
    }
    if (((unaff_x26 == (undefined8 *)0x0) || (auVar24 != *(undefined1 (*) [16])(unaff_x26 + 2))) ||
       (unaff_x26[4] != unaff_x22)) {
      unaff_x30 = 0x152dcf4;
      register0x00000008 = (BADSPACEBASE *)&uStack_80;
      unaff_x20 = param_2;
      unaff_x29 = puVar3;
      auVar25 = auVar6;
      goto
      __ZN5ProxyL10OpenDirectERKNSt3__112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEE;
    }
    *(undefined4 *)param_1 = *(undefined4 *)(unaff_x26 + 6);
    param_1[1] = unaff_x26[7];
    lVar15 = unaff_x26[8];
    param_1[2] = lVar15;
    lVar18 = 0;
    if (lVar15 != 0) {
      lVar18 = *(long *)(lVar15 + 8);
      *(long *)(lVar15 + 8) = lVar18 + 1;
    }
    func_0x0116e72c(lVar18,unaff_x21,param_2);
    plVar20 = plStack_60;
    if (plStack_60 != (long *)0x0) {
      LOAcquire();
      lVar18 = plStack_60[1];
      plStack_60[1] = lVar18 + -1;
      LORelease();
      if (lVar18 == 0) {
        (**(code **)(*plStack_60 + 0x10))(plStack_60);
        __ZNSt3__119__shared_weak_count14__release_weakEv(plVar20);
      }
    }
    if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_58) {
      return;
    }
  }
  else {
    param_1 = unaff_x19;
    if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_58)
    goto __ZN5ProxyL10OpenDirectERKNSt3__112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEE;
  }
  unaff_x22 = ___stack_chk_fail();
  if (plStack_60 != (long *)0x0) {
    LOAcquire();
    lVar18 = plStack_60[1];
    plStack_60[1] = lVar18 + -1;
    LORelease();
    if (lVar18 == 0) {
      (**(code **)(*plStack_60 + 0x10))(plStack_60);
      __ZNSt3__119__shared_weak_count14__release_weakEv(plStack_60);
    }
  }
  unaff_x30 = 0x152de40;
  auVar25 = __Unwind_Resume(unaff_x22);
  register0x00000008 = (BADSPACEBASE *)&uStack_80;
  param_1 = plStack_60;
  unaff_x20 = param_2;
  unaff_x29 = puVar3;
__ZN5ProxyL10OpenDirectERKNSt3__112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEE:
  puVar14 = auVar25._8_8_;
  piVar9 = auVar25._0_8_;
  *(undefined8 *)((long)register0x00000008 + -0x60) = unaff_x28;
  *(undefined8 *)((long)register0x00000008 + -0x58) = unaff_x27;
  *(undefined8 **)((long)register0x00000008 + -0x50) = unaff_x26;
  *(undefined8 *)((long)register0x00000008 + -0x48) = unaff_x25;
  *(long *)((long)register0x00000008 + -0x40) = auVar24._8_8_;
  *(long *)((long)register0x00000008 + -0x38) = auVar24._0_8_;
  *(long *)((long)register0x00000008 + -0x30) = unaff_x22;
  *(long *)((long)register0x00000008 + -0x28) = unaff_x21;
  *(undefined8 **)((long)register0x00000008 + -0x20) = unaff_x20;
  *(long **)((long)register0x00000008 + -0x18) = param_1;
  *(undefined1 **)((long)register0x00000008 + -0x10) = unaff_x29;
  *(undefined8 *)((long)register0x00000008 + -8) = unaff_x30;
  *(undefined8 *)((long)register0x00000008 + -0x78) = *(undefined8 *)PTR____stack_chk_guard_01d15188
  ;
  *(undefined8 *)((long)register0x00000008 + -0x4d8) = 0;
  *(undefined8 *)((long)register0x00000008 + -0x4d0) = 0;
  *(undefined8 *)((long)register0x00000008 + -0x4c8) = 0;
  uVar11 = puVar14[1];
  puVar10 = (undefined8 *)*puVar14;
  if (-1 < (char)*(byte *)((long)puVar14 + 0x17)) {
    uVar11 = (ulong)*(byte *)((long)puVar14 + 0x17);
    puVar10 = puVar14;
  }
  func_0x0110a298((undefined1 *)((long)register0x00000008 + -0x4d8),puVar10,(long)puVar10 + uVar11);
  puVar3 = *(undefined1 **)((long)register0x00000008 + -0x4d8);
  if (-1 < *(char *)((long)register0x00000008 + -0x4c1)) {
    puVar3 = (undefined1 *)((long)register0x00000008 + -0x4d8);
  }
  func_0x0152f114((undefined1 *)((long)register0x00000008 + -0x2b8),puVar3,4);
  if (*(int *)((long)register0x00000008 +
              *(long *)(*(long *)((long)register0x00000008 + -0x2b8) + -0x18) + -0x298) == 0) {
    if ((__ZGVZN5Proxy11GetBackendsEvE8backends & 1) == 0) goto LAB_0152e58c;
    goto LAB_0152def8;
  }
  *piVar9 = 0x15;
  piVar9[2] = 0;
  piVar9[3] = 0;
  piVar9[4] = 0;
  piVar9[5] = 0;
  do {
    piVar9 = (int *)PTR___ZTTNSt3__114basic_ifstreamIcNS_11char_traitsIcEEEE_01d14f68;
    lVar18 = *(long *)PTR___ZTTNSt3__114basic_ifstreamIcNS_11char_traitsIcEEEE_01d14f68;
    *(long *)((long)register0x00000008 + -0x2b8) = lVar18;
    *(undefined8 *)((long)register0x00000008 + *(long *)(lVar18 + -0x18) + -0x2b8) =
         *(undefined8 *)(PTR___ZTTNSt3__114basic_ifstreamIcNS_11char_traitsIcEEEE_01d14f68 + 0x18);
    __ZNSt3__113basic_filebufIcNS_11char_traitsIcEEED1Ev
              ((undefined1 *)((long)register0x00000008 + -0x2a8));
    __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEED2Ev
              ((undefined1 *)((long)register0x00000008 + -0x2b8),(undefined *)((long)piVar9 + 8));
    __ZNSt3__19basic_iosIcNS_11char_traitsIcEEED2Ev
              ((undefined1 *)((long)register0x00000008 + -0x110));
    if (*(char *)((long)register0x00000008 + -0x4c1) < '\0') {
      __ZdlPv(*(undefined8 *)((long)register0x00000008 + -0x4d8));
    }
    if (*(long *)PTR____stack_chk_guard_01d15188 == *(long *)((long)register0x00000008 + -0x78)) {
      return;
    }
    ___stack_chk_fail();
LAB_0152e58c:
    iVar8 = ___cxa_guard_acquire(&__ZGVZN5Proxy11GetBackendsEvE8backends);
    if (iVar8 != 0) {
      func_0x01538d88();
      ___cxa_atexit(&
                    __ZNSt3__16vectorIPKN5Proxy16BackendInterfaceENS_9allocatorIS4_EEED1B8ne180100Ev
                    ,&__ZZN5Proxy11GetBackendsEvE8backends,0);
      ___cxa_guard_release(&__ZGVZN5Proxy11GetBackendsEvE8backends);
    }
LAB_0152def8:
    lVar15 = ___ZZN5Proxy11GetBackendsEvE8backends;
    *(undefined8 *)((long)register0x00000008 + -0x4f0) = 0;
    *(undefined8 *)((long)register0x00000008 + -0x4e8) = 0;
    *(undefined8 *)((long)register0x00000008 + -0x4e0) = 0;
    lVar18 = lRam0000000002061738 - ___ZZN5Proxy11GetBackendsEvE8backends;
    if (lVar18 == 0) {
      puVar14 = (undefined8 *)0x0;
      puVar10 = (undefined8 *)0x0;
    }
    else {
      if (lVar18 < 0) {
        func_0x00108ee8((undefined1 *)((long)register0x00000008 + -0x4f0));
                    /* WARNING: Does not return */
        pcVar7 = (code *)SoftwareBreakpoint(1,0x152e5d8);
        (*pcVar7)();
      }
      puVar10 = (undefined8 *)__Znwm(lVar18);
      puVar14 = puVar10 + (lVar18 >> 3);
      *(undefined8 **)((long)register0x00000008 + -0x4f0) = puVar10;
      *(undefined8 **)((long)register0x00000008 + -0x4e0) = puVar14;
      _memcpy(puVar10,lVar15,lVar18);
      *(undefined8 **)((long)register0x00000008 + -0x4e8) = puVar14;
    }
    *(undefined8 *)((long)register0x00000008 + -0x520) = 0;
    *(undefined4 *)((long)register0x00000008 + -0x518) = 0;
    *(undefined1 *)((long)register0x00000008 + -0x4f9) = 0;
    *(undefined1 *)((long)register0x00000008 + -0x510) = 0;
    *(undefined8 *)((long)register0x00000008 + -0x4f8) = 0;
    if (puVar10 != puVar14) {
      puVar1 = (undefined8 *)((long)register0x00000008 + -0x510);
      puVar2 = (undefined8 *)((long)register0x00000008 + -0x5b0);
      do {
        plVar20 = (long *)*puVar10;
        uVar11 = (**(code **)(*plVar20 + 0x10))
                           (plVar20,(undefined1 *)((long)register0x00000008 + -0x2b8));
        *(undefined8 *)((long)register0x00000008 + -0x338) = 0;
        *(undefined8 *)((long)register0x00000008 + -0x340) = 0;
        *(undefined8 *)((long)register0x00000008 + -0x328) = 0;
        *(undefined8 *)((long)register0x00000008 + -0x330) = 0;
        *(undefined8 *)((long)register0x00000008 + -0x318) = 0;
        *(undefined8 *)((long)register0x00000008 + -800) = 0;
        *(undefined8 *)((long)register0x00000008 + -0x308) = 0;
        *(undefined8 *)((long)register0x00000008 + -0x310) = 0;
        *(undefined8 *)((long)register0x00000008 + -0x2f8) = 0;
        *(undefined8 *)((long)register0x00000008 + -0x300) = 0;
        *(undefined8 *)((long)register0x00000008 + -0x2e8) = 0;
        *(undefined8 *)((long)register0x00000008 + -0x2f0) = 0;
        *(undefined8 *)((long)register0x00000008 + -0x2d8) = 0;
        *(undefined8 *)((long)register0x00000008 + -0x2e0) = 0;
        *(undefined8 *)((long)register0x00000008 + -0x2c8) = 0;
        *(undefined8 *)((long)register0x00000008 + -0x2d0) = 0;
        *(undefined8 *)((long)register0x00000008 + -0x2c0) = 0;
        __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgENS_4fposI11__mbstate_tEE
                  ((undefined1 *)((long)register0x00000008 + -0x2b8),
                   (undefined1 *)((long)register0x00000008 + -0x340));
        if ((uVar11 & 1) != 0) {
          iVar8 = (**(code **)(*plVar20 + 0x18))
                            (plVar20,(undefined1 *)((long)register0x00000008 + -0x490),
                             (undefined1 *)((long)register0x00000008 + -0x2b8));
          *(undefined8 *)((long)register0x00000008 + -0x3c8) = 0;
          *(undefined8 *)((long)register0x00000008 + -0x3d0) = 0;
          *(undefined8 *)((long)register0x00000008 + -0x3b8) = 0;
          *(undefined8 *)((long)register0x00000008 + -0x3c0) = 0;
          *(undefined8 *)((long)register0x00000008 + -0x3a8) = 0;
          *(undefined8 *)((long)register0x00000008 + -0x3b0) = 0;
          *(undefined8 *)((long)register0x00000008 + -0x398) = 0;
          *(undefined8 *)((long)register0x00000008 + -0x3a0) = 0;
          *(undefined8 *)((long)register0x00000008 + -0x388) = 0;
          *(undefined8 *)((long)register0x00000008 + -0x390) = 0;
          *(undefined8 *)((long)register0x00000008 + -0x378) = 0;
          *(undefined8 *)((long)register0x00000008 + -0x380) = 0;
          *(undefined8 *)((long)register0x00000008 + -0x368) = 0;
          *(undefined8 *)((long)register0x00000008 + -0x370) = 0;
          *(undefined8 *)((long)register0x00000008 + -0x358) = 0;
          *(undefined8 *)((long)register0x00000008 + -0x360) = 0;
          *(undefined8 *)((long)register0x00000008 + -0x350) = 0;
          __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgENS_4fposI11__mbstate_tEE
                    ((undefined1 *)((long)register0x00000008 + -0x2b8),
                     (undefined1 *)((long)register0x00000008 + -0x3d0));
          if (iVar8 == 0) {
            uVar21 = (ulong)*(uint *)((long)register0x00000008 + -0x490);
            plVar12 = (long *)func_0x015380bc();
            puVar4 = (undefined8 *)*plVar12;
            uVar11 = (plVar12[1] - (long)puVar4 >> 4) * -0x5555555555555555;
            if (uVar11 < uVar21 || uVar11 - uVar21 == 0) {
              uVar16 = *puVar4;
              *(undefined4 *)((long)register0x00000008 + -0x5b8) = *(undefined4 *)(puVar4 + 1);
              *(undefined8 *)((long)register0x00000008 + -0x5c0) = uVar16;
              if (-1 < *(char *)((long)puVar4 + 0x27)) {
                uVar21 = 0;
                puVar17 = puVar4 + 2;
                goto LAB_0152e098;
              }
              func_0x00109e84(puVar2,puVar4[2],puVar4[3]);
              uVar21 = 0;
            }
            else {
              puVar19 = puVar4 + uVar21 * 6;
              uVar16 = *puVar19;
              *(undefined4 *)((long)register0x00000008 + -0x5b8) = *(undefined4 *)(puVar19 + 1);
              *(undefined8 *)((long)register0x00000008 + -0x5c0) = uVar16;
              puVar17 = puVar19 + 2;
              if (*(char *)((long)puVar19 + 0x27) < '\0') {
                func_0x00109e84(puVar2,*puVar17,puVar4[uVar21 * 6 + 3]);
              }
              else {
LAB_0152e098:
                uVar23 = puVar17[1];
                uVar16 = *puVar17;
                *(undefined8 *)((long)register0x00000008 + -0x5a0) = puVar17[2];
                *(undefined8 *)((long)register0x00000008 + -0x5a8) = uVar23;
                *puVar2 = uVar16;
              }
            }
            plVar12 = (long *)puVar4[uVar21 * 6 + 5];
            *(long **)((long)register0x00000008 + -0x598) = plVar12;
            *(undefined8 *)((long)register0x00000008 + -0x520) =
                 *(undefined8 *)((long)register0x00000008 + -0x5c0);
            *(undefined4 *)((long)register0x00000008 + -0x518) =
                 *(undefined4 *)((long)register0x00000008 + -0x5b8);
            if (*(char *)((long)register0x00000008 + -0x4f9) < '\0') {
              __ZdlPv(*(undefined8 *)((long)register0x00000008 + -0x510));
              plVar12 = *(long **)((long)register0x00000008 + -0x598);
            }
            *(undefined8 *)((long)register0x00000008 + -0x508) =
                 *(undefined8 *)((long)register0x00000008 + -0x5a8);
            *puVar1 = *puVar2;
            *(undefined8 *)((long)register0x00000008 + -0x500) =
                 *(undefined8 *)((long)register0x00000008 + -0x5a0);
            *(long **)((long)register0x00000008 + -0x4f8) = plVar12;
            if (((*(int *)((long)register0x00000008 + -0x520) != 0) &&
                (*(int *)((long)register0x00000008 + -0x51c) != 0)) &&
               ((*(int *)((long)register0x00000008 + -0x518) != 0 && (plVar12 != (long *)0x0)))) {
              if (plVar12 == plVar20) {
                if (__DEBUG_PROXY_CREATE != 0) {
                  puVar10 = *(undefined8 **)((long)register0x00000008 + -0x510);
                  if (-1 < *(char *)((long)register0x00000008 + -0x4f9)) {
                    puVar10 = puVar1;
                  }
                  puVar3 = *(undefined1 **)((long)register0x00000008 + -0x4d8);
                  if (-1 < *(char *)((long)register0x00000008 + -0x4c1)) {
                    puVar3 = (undefined1 *)((long)register0x00000008 + -0x4d8);
                  }
                  *(undefined8 **)((long)register0x00000008 + -0x5e0) = puVar10;
                  *(undefined1 **)((long)register0x00000008 + -0x5d8) = puVar3;
                  func_0x005742a8("Proxy: Opened version [%s] at: %s");
                }
                *(undefined1 *)((long)register0x00000008 + -0x5a0) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x5b8) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x5c0) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x5a8) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x5b0) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x590) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x598) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x580) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x588) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x570) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x578) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x560) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x568) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x550) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x558) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x540) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x548) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x530) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x538) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x528) = 0;
                iVar8 = (**(code **)(*plVar20 + 0x20))
                                  (plVar20,(undefined1 *)((long)register0x00000008 + -0x5c0),
                                   *(undefined4 *)((long)register0x00000008 + -0x518),
                                   (undefined1 *)((long)register0x00000008 + -0x2b8));
                *(undefined8 *)((long)register0x00000008 + -0x458) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x460) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x448) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x450) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x438) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x440) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x428) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x430) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x418) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x420) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x408) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x410) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x3f8) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x400) = 0;
                *(undefined8 *)((long)register0x00000008 + -1000) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x3f0) = 0;
                *(undefined8 *)((long)register0x00000008 + -0x3e0) = 0;
                __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgENS_4fposI11__mbstate_tEE
                          ((undefined1 *)((long)register0x00000008 + -0x2b8),
                           (undefined1 *)((long)register0x00000008 + -0x460));
                if (iVar8 == 0) {
                  plVar12 = (long *)__Znwm(0xa0);
                  plVar12[1] = 0;
                  plVar12[2] = 0;
                  *plVar12 = (long)&
                                   PTR___ZNSt3__120__shared_ptr_emplaceIN5Proxy8LoadInfoENS_9allocatorIS2_EEED1Ev_01ffce60
                  ;
                  plVar22 = plVar12 + 3;
                  *plVar22 = *(long *)((long)register0x00000008 + -0x5c0);
                  plVar13 = plVar12 + 4;
                  plVar12[5] = 0;
                  *plVar13 = 0;
                  plVar12[0x11] = 0;
                  plVar12[0x10] = 0;
                  plVar12[0x13] = 0;
                  plVar12[0x12] = 0;
                  plVar12[7] = 0;
                  plVar12[6] = 0;
                  plVar12[9] = 0;
                  plVar12[8] = 0;
                  plVar12[0xb] = 0;
                  plVar12[10] = 0;
                  plVar12[0xd] = 0;
                  plVar12[0xc] = 0;
                  plVar12[0xf] = 0;
                  plVar12[0xe] = 0;
                  *(long **)((long)register0x00000008 + -0x5d0) = plVar22;
                  *(long **)((long)register0x00000008 + -0x5c8) = plVar12;
                  *(undefined1 *)(plVar12 + 0x13) =
                       *(undefined1 *)((long)register0x00000008 + -0x5a0);
                  if (*(int *)((long)register0x00000008 + -0x51c) == 0) {
LAB_0152e354:
                    *piVar9 = 0;
                    piVar9[2] = 0;
                    piVar9[3] = 0;
                    piVar9[4] = 0;
                    piVar9[5] = 0;
                    puVar14 = (undefined8 *)__Znwm(0x78);
                    puVar14[1] = 0;
                    puVar14[2] = 0;
                    *puVar14 = &
                               PTR___ZNSt3__120__shared_ptr_emplaceIN5Proxy4FileENS_9allocatorIS2_EEED1Ev_01ffceb0
                    ;
                    *(undefined8 *)((long)register0x00000008 + -0x490) =
                         *(undefined8 *)((long)register0x00000008 + -0x520);
                    *(undefined4 *)((long)register0x00000008 + -0x488) =
                         *(undefined4 *)((long)register0x00000008 + -0x518);
                    puVar10 = (undefined8 *)((long)register0x00000008 + -0x480);
                    if (*(char *)((long)register0x00000008 + -0x4f9) < '\0') {
                      func_0x00109e84(puVar10,*(undefined8 *)((long)register0x00000008 + -0x510),
                                      *(undefined8 *)((long)register0x00000008 + -0x508));
                    }
                    else {
                      *(undefined8 *)((long)register0x00000008 + -0x478) =
                           *(undefined8 *)((long)register0x00000008 + -0x508);
                      *puVar10 = *puVar1;
                      *(undefined8 *)((long)register0x00000008 + -0x470) =
                           *(undefined8 *)((long)register0x00000008 + -0x500);
                    }
                    *(undefined8 *)((long)register0x00000008 + -0x468) =
                         *(undefined8 *)((long)register0x00000008 + -0x4f8);
                    if (*(char *)((long)register0x00000008 + -0x4c1) < '\0') {
                      func_0x00109e84((undefined1 *)((long)register0x00000008 + -0x4b0),
                                      *(undefined8 *)((long)register0x00000008 + -0x4d8),
                                      *(undefined8 *)((long)register0x00000008 + -0x4d0));
                    }
                    else {
                      *(undefined8 *)((long)register0x00000008 + -0x4a8) =
                           *(undefined8 *)((long)register0x00000008 + -0x4d0);
                      *(undefined8 *)((long)register0x00000008 + -0x4b0) =
                           *(undefined8 *)((long)register0x00000008 + -0x4d8);
                      *(undefined8 *)((long)register0x00000008 + -0x4a0) =
                           *(undefined8 *)((long)register0x00000008 + -0x4c8);
                    }
                    *(long **)((long)register0x00000008 + -0x4c0) = plVar22;
                    *(long **)((long)register0x00000008 + -0x4b8) = plVar12;
                    plVar12[1] = plVar12[1] + 1;
                    uVar16 = *(undefined8 *)((long)register0x00000008 + -0x490);
                    puVar14[3] = plVar20;
                    puVar14[4] = uVar16;
                    *(undefined4 *)(puVar14 + 5) =
                         *(undefined4 *)((long)register0x00000008 + -0x488);
                    if (*(char *)((long)register0x00000008 + -0x469) < '\0') {
                      func_0x00109e84(puVar14 + 6,*(undefined8 *)((long)register0x00000008 + -0x480)
                                      ,*(undefined8 *)((long)register0x00000008 + -0x478));
                    }
                    else {
                      uVar16 = *puVar10;
                      puVar14[7] = *(undefined8 *)((long)register0x00000008 + -0x478);
                      puVar14[6] = uVar16;
                      puVar14[8] = *(undefined8 *)((long)register0x00000008 + -0x470);
                    }
                    puVar14[9] = *(undefined8 *)((long)register0x00000008 + -0x468);
                    uVar16 = *(undefined8 *)((long)register0x00000008 + -0x4b0);
                    puVar14[0xb] = *(undefined8 *)((long)register0x00000008 + -0x4a8);
                    puVar14[10] = uVar16;
                    uVar16 = *(undefined8 *)((long)register0x00000008 + -0x4a0);
                    *(undefined8 *)((long)register0x00000008 + -0x4b0) = 0;
                    *(undefined8 *)((long)register0x00000008 + -0x4a8) = 0;
                    *(undefined8 *)((long)register0x00000008 + -0x4a0) = 0;
                    puVar14[0xc] = uVar16;
                    puVar14[0xd] = plVar22;
                    puVar14[0xe] = plVar12;
                    plVar20 = plVar12 + 1;
                    *plVar20 = *plVar20 + 1;
                    LOAcquire();
                    lVar18 = *plVar20;
                    *plVar20 = lVar18 + -1;
                    LORelease();
                    if (lVar18 == 0) {
                      (**(code **)(*plVar12 + 0x10))(plVar12);
                      __ZNSt3__119__shared_weak_count14__release_weakEv(plVar12);
                      if (-1 < *(char *)((long)register0x00000008 + -0x499)) goto LAB_0152e478;
LAB_0152e4b4:
                      __ZdlPv(*(undefined8 *)((long)register0x00000008 + -0x4b0));
                      cVar5 = *(char *)((long)register0x00000008 + -0x469);
                    }
                    else {
                      if (*(char *)((long)register0x00000008 + -0x499) < '\0') goto LAB_0152e4b4;
LAB_0152e478:
                      cVar5 = *(char *)((long)register0x00000008 + -0x469);
                    }
                    if (cVar5 < '\0') {
                      __ZdlPv(*(undefined8 *)((long)register0x00000008 + -0x480));
                      *(undefined8 **)(piVar9 + 2) = puVar14 + 3;
                      *(undefined8 **)(piVar9 + 4) = puVar14;
                      plVar12 = *(long **)((long)register0x00000008 + -0x5c8);
                    }
                    else {
                      *(undefined8 **)(piVar9 + 2) = puVar14 + 3;
                      *(undefined8 **)(piVar9 + 4) = puVar14;
                      plVar12 = *(long **)((long)register0x00000008 + -0x5c8);
                    }
                    if (plVar12 == (long *)0x0) goto LAB_0152e500;
                  }
                  else {
                    if (*(int *)((long)register0x00000008 + -0x51c) == 1) {
                      func_0x01178448(plVar13,(undefined1 *)((long)register0x00000008 + -0x598));
                      func_0x003144c0(plVar12 + 0x10,*(long *)((long)register0x00000008 + -0x538),
                                      *(long *)((long)register0x00000008 + -0x530),
                                      *(long *)((long)register0x00000008 + -0x530) -
                                      *(long *)((long)register0x00000008 + -0x538));
                      goto LAB_0152e354;
                    }
                    iVar8 = __ZN5Proxy8Metadata11DeserializeERS0_RKNSt3__16vectorIhNS2_9allocatorIhEEEEj
                                      (plVar13,(ulong)((long)register0x00000008 + -0x5c0) | 8);
                    if (iVar8 == 0) goto LAB_0152e354;
                    *piVar9 = iVar8;
                    piVar9[2] = 0;
                    piVar9[3] = 0;
                    piVar9[4] = 0;
                    piVar9[5] = 0;
                  }
                  LOAcquire();
                  lVar18 = plVar12[1];
                  plVar12[1] = lVar18 + -1;
                  LORelease();
                  if (lVar18 == 0) {
                    (**(code **)(*plVar12 + 0x10))(plVar12);
                    __ZNSt3__119__shared_weak_count14__release_weakEv(plVar12);
                  }
                }
                else {
                  *piVar9 = iVar8;
                  piVar9[2] = 0;
                  piVar9[3] = 0;
                  piVar9[4] = 0;
                  piVar9[5] = 0;
                }
LAB_0152e500:
                if (*(long *)((long)register0x00000008 + -0x538) != 0) {
                  *(long *)((long)register0x00000008 + -0x530) =
                       *(long *)((long)register0x00000008 + -0x538);
                  __ZdlPv();
                }
                if (*(char *)((long)register0x00000008 + -0x539) < '\0') {
                  __ZdlPv(*(undefined8 *)((long)register0x00000008 + -0x550));
                  if (-1 < *(char *)((long)register0x00000008 + -0x551)) goto LAB_0152e520;
LAB_0152e54c:
                  __ZdlPv(*(undefined8 *)((long)register0x00000008 + -0x568));
                  if (-1 < *(char *)((long)register0x00000008 + -0x569)) goto LAB_0152e528;
LAB_0152e55c:
                  __ZdlPv(*(undefined8 *)((long)register0x00000008 + -0x580));
                  if (-1 < *(char *)((long)register0x00000008 + -0x581)) goto LAB_0152e530;
LAB_0152e56c:
                  __ZdlPv(*(undefined8 *)((long)register0x00000008 + -0x598));
                  lVar18 = *(long *)((long)register0x00000008 + -0x5b8);
                }
                else {
                  if (*(char *)((long)register0x00000008 + -0x551) < '\0') goto LAB_0152e54c;
LAB_0152e520:
                  if (*(char *)((long)register0x00000008 + -0x569) < '\0') goto LAB_0152e55c;
LAB_0152e528:
                  if (*(char *)((long)register0x00000008 + -0x581) < '\0') goto LAB_0152e56c;
LAB_0152e530:
                  lVar18 = *(long *)((long)register0x00000008 + -0x5b8);
                }
                if (lVar18 != 0) {
                  *(long *)((long)register0x00000008 + -0x5b0) = lVar18;
                  __ZdlPv();
                }
                goto LAB_0152e154;
              }
              puVar4 = *(undefined8 **)((long)register0x00000008 + -0x510);
              if (-1 < *(char *)((long)register0x00000008 + -0x4f9)) {
                puVar4 = puVar1;
              }
              *(undefined8 **)((long)register0x00000008 + -0x5e0) = puVar4;
              func_0x00574348("Proxy: ignoring candidate backend: version [%s] has another backend")
              ;
            }
          }
        }
        puVar10 = puVar10 + 1;
      } while (puVar10 != puVar14);
    }
    *piVar9 = 0x15;
    piVar9[2] = 0;
    piVar9[3] = 0;
    piVar9[4] = 0;
    piVar9[5] = 0;
LAB_0152e154:
    if (*(char *)((long)register0x00000008 + -0x4f9) < '\0') {
      __ZdlPv(*(undefined8 *)((long)register0x00000008 + -0x510));
    }
    if (*(long *)((long)register0x00000008 + -0x4f0) != 0) {
      __ZdlPv();
    }
  } while( true );
}


/* __ZN5ProxyL10OpenDirectERKNSt3__112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEE @ 0152de40 */

/* WARNING: Type propagation algorithm not settling */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __ZN5ProxyL10OpenDirectERKNSt3__112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEE
               (int *param_1,undefined8 *param_2)

{
  undefined8 *******pppppppuVar1;
  long lVar2;
  undefined8 *puVar3;
  code *pcVar4;
  long lVar5;
  int iVar6;
  undefined8 *puVar7;
  ulong uVar8;
  long *plVar9;
  long *plVar10;
  ulong *puVar11;
  ulong *puVar12;
  long *plVar13;
  ulong uVar14;
  ulong *puVar15;
  ulong uStack_5c0;
  ulong uStack_5b8;
  ulong uStack_5b0;
  ulong uStack_5a8;
  ulong uStack_5a0;
  long *plStack_598;
  undefined8 uStack_590;
  long lStack_588;
  undefined8 uStack_580;
  undefined8 uStack_578;
  long lStack_570;
  undefined8 uStack_568;
  undefined8 uStack_560;
  long lStack_558;
  undefined8 uStack_550;
  undefined8 uStack_548;
  long lStack_540;
  long lStack_538;
  long lStack_530;
  undefined8 uStack_528;
  undefined8 uStack_520;
  int iStack_518;
  ulong uStack_510;
  ulong uStack_508;
  ulong uStack_500;
  long *plStack_4f8;
  undefined8 *puStack_4f0;
  undefined8 *puStack_4e8;
  undefined8 *puStack_4e0;
  undefined8 *******pppppppuStack_4d8;
  undefined8 uStack_4d0;
  long lStack_4c8;
  ulong *puStack_4c0;
  long *plStack_4b8;
  undefined8 *******pppppppuStack_4b0;
  undefined8 uStack_4a8;
  long lStack_4a0;
  ulong uStack_490;
  int iStack_488;
  ulong uStack_480;
  ulong uStack_478;
  ulong uStack_470;
  long *plStack_468;
  undefined8 uStack_460;
  undefined8 uStack_458;
  undefined8 uStack_450;
  undefined8 uStack_448;
  undefined8 uStack_440;
  undefined8 uStack_438;
  undefined8 uStack_430;
  undefined8 uStack_428;
  undefined8 uStack_420;
  undefined8 uStack_418;
  undefined8 uStack_410;
  undefined8 uStack_408;
  undefined8 uStack_400;
  undefined8 uStack_3f8;
  undefined8 uStack_3f0;
  undefined8 uStack_3e8;
  undefined8 uStack_3e0;
  undefined8 uStack_3d0;
  undefined8 uStack_3c8;
  undefined8 uStack_3c0;
  undefined8 uStack_3b8;
  undefined8 uStack_3b0;
  undefined8 uStack_3a8;
  undefined8 uStack_3a0;
  undefined8 uStack_398;
  undefined8 uStack_390;
  undefined8 uStack_388;
  undefined8 uStack_380;
  undefined8 uStack_378;
  undefined8 uStack_370;
  undefined8 uStack_368;
  undefined8 uStack_360;
  undefined8 uStack_358;
  undefined8 uStack_350;
  undefined8 uStack_340;
  undefined8 uStack_338;
  undefined8 uStack_330;
  undefined8 uStack_328;
  undefined8 uStack_320;
  undefined8 uStack_318;
  undefined8 uStack_310;
  undefined8 uStack_308;
  undefined8 uStack_300;
  undefined8 uStack_2f8;
  undefined8 uStack_2f0;
  undefined8 uStack_2e8;
  undefined8 uStack_2e0;
  undefined8 uStack_2d8;
  undefined8 uStack_2d0;
  undefined8 uStack_2c8;
  undefined8 uStack_2c0;
  long alStack_2b8 [2];
  undefined1 auStack_2a8 [16];
  int aiStack_298 [98];
  undefined1 auStack_110 [152];
  long lStack_78;

  lStack_78 = *(long *)PTR____stack_chk_guard_01d15188;
  pppppppuStack_4d8 = (undefined8 *******)0x0;
  uStack_4d0 = 0;
  lStack_4c8 = 0;
  uVar8 = param_2[1];
  puVar7 = (undefined8 *)*param_2;
  if (-1 < (char)*(byte *)((long)param_2 + 0x17)) {
    uVar8 = (ulong)*(byte *)((long)param_2 + 0x17);
    puVar7 = param_2;
  }
  func_0x0110a298(&pppppppuStack_4d8,puVar7,(long)puVar7 + uVar8);
  pppppppuVar1 = pppppppuStack_4d8;
  if (-1 < lStack_4c8) {
    pppppppuVar1 = &pppppppuStack_4d8;
  }
  func_0x0152f114(alStack_2b8,pppppppuVar1,4);
  if (*(int *)((long)aiStack_298 + *(long *)(alStack_2b8[0] + -0x18)) == 0) {
    if ((__ZGVZN5Proxy11GetBackendsEvE8backends & 1) == 0) goto LAB_0152e58c;
    goto LAB_0152def8;
  }
  *param_1 = 0x15;
  param_1[2] = 0;
  param_1[3] = 0;
  param_1[4] = 0;
  param_1[5] = 0;
  do {
    param_1 = (int *)PTR___ZTTNSt3__114basic_ifstreamIcNS_11char_traitsIcEEEE_01d14f68;
    alStack_2b8[0] = *(long *)PTR___ZTTNSt3__114basic_ifstreamIcNS_11char_traitsIcEEEE_01d14f68;
    *(undefined8 *)((long)alStack_2b8 + *(long *)(alStack_2b8[0] + -0x18)) =
         *(undefined8 *)(PTR___ZTTNSt3__114basic_ifstreamIcNS_11char_traitsIcEEEE_01d14f68 + 0x18);
    __ZNSt3__113basic_filebufIcNS_11char_traitsIcEEED1Ev(auStack_2a8);
    __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEED2Ev
              (alStack_2b8,(undefined *)((long)param_1 + 8));
    __ZNSt3__19basic_iosIcNS_11char_traitsIcEEED2Ev(auStack_110);
    if (lStack_4c8 < 0) {
      __ZdlPv(pppppppuStack_4d8);
    }
    if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_78) {
      return;
    }
    ___stack_chk_fail();
LAB_0152e58c:
    iVar6 = ___cxa_guard_acquire(&__ZGVZN5Proxy11GetBackendsEvE8backends);
    if (iVar6 != 0) {
      func_0x01538d88();
      ___cxa_atexit(&
                    __ZNSt3__16vectorIPKN5Proxy16BackendInterfaceENS_9allocatorIS4_EEED1B8ne180100Ev
                    ,&__ZZN5Proxy11GetBackendsEvE8backends,0);
      ___cxa_guard_release(&__ZGVZN5Proxy11GetBackendsEvE8backends);
    }
LAB_0152def8:
    lVar2 = ___ZZN5Proxy11GetBackendsEvE8backends;
    puStack_4f0 = (undefined8 *)0x0;
    puStack_4e8 = (undefined8 *)0x0;
    puStack_4e0 = (undefined8 *)0x0;
    lVar5 = lRam0000000002061738 - ___ZZN5Proxy11GetBackendsEvE8backends;
    if (lVar5 == 0) {
      puVar7 = (undefined8 *)0x0;
    }
    else {
      if (lVar5 < 0) {
        func_0x00108ee8(&puStack_4f0);
                    /* WARNING: Does not return */
        pcVar4 = (code *)SoftwareBreakpoint(1,0x152e5d8);
        (*pcVar4)();
      }
      puVar7 = (undefined8 *)__Znwm(lVar5);
      puStack_4f0 = puVar7;
      puStack_4e0 = puVar7 + (lVar5 >> 3);
      _memcpy(puVar7,lVar2,lVar5);
      puStack_4e8 = puVar7 + (lVar5 >> 3);
    }
    puVar3 = puStack_4e8;
    uStack_520 = 0;
    iStack_518 = 0;
    uStack_500 = uStack_500 & 0xffffffffffffff;
    uStack_510 = uStack_510 & 0xffffffffffffff00;
    plStack_4f8 = (long *)0x0;
    if (puVar7 != puStack_4e8) {
      do {
        plVar13 = (long *)*puVar7;
        uVar8 = (**(code **)(*plVar13 + 0x10))(plVar13,alStack_2b8);
        uStack_338 = 0;
        uStack_340 = 0;
        uStack_328 = 0;
        uStack_330 = 0;
        uStack_318 = 0;
        uStack_320 = 0;
        uStack_308 = 0;
        uStack_310 = 0;
        uStack_2f8 = 0;
        uStack_300 = 0;
        uStack_2e8 = 0;
        uStack_2f0 = 0;
        uStack_2d8 = 0;
        uStack_2e0 = 0;
        uStack_2c8 = 0;
        uStack_2d0 = 0;
        uStack_2c0 = 0;
        __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgENS_4fposI11__mbstate_tEE
                  (alStack_2b8,&uStack_340);
        if ((uVar8 & 1) != 0) {
          iVar6 = (**(code **)(*plVar13 + 0x18))(plVar13,&uStack_490,alStack_2b8);
          uStack_3c8 = 0;
          uStack_3d0 = 0;
          uStack_3b8 = 0;
          uStack_3c0 = 0;
          uStack_3a8 = 0;
          uStack_3b0 = 0;
          uStack_398 = 0;
          uStack_3a0 = 0;
          uStack_388 = 0;
          uStack_390 = 0;
          uStack_378 = 0;
          uStack_380 = 0;
          uStack_368 = 0;
          uStack_370 = 0;
          uStack_358 = 0;
          uStack_360 = 0;
          uStack_350 = 0;
          __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgENS_4fposI11__mbstate_tEE
                    (alStack_2b8,&uStack_3d0);
          if (iVar6 == 0) {
            uVar14 = uStack_490 & 0xffffffff;
            plVar9 = (long *)func_0x015380bc();
            puVar15 = (ulong *)*plVar9;
            uVar8 = (plVar9[1] - (long)puVar15 >> 4) * -0x5555555555555555;
            if (uVar8 < uVar14 || uVar8 - uVar14 == 0) {
              uStack_5c0 = *puVar15;
              uStack_5b8 = CONCAT44(uStack_5b8._4_4_,(int)puVar15[1]);
              if (-1 < *(char *)((long)puVar15 + 0x27)) {
                uVar14 = 0;
                puVar11 = puVar15 + 2;
                goto LAB_0152e098;
              }
              func_0x00109e84(&uStack_5b0,puVar15[2],puVar15[3]);
              uVar14 = 0;
            }
            else {
              puVar12 = puVar15 + uVar14 * 6;
              uStack_5c0 = *puVar12;
              uStack_5b8 = CONCAT44(uStack_5b8._4_4_,(int)puVar12[1]);
              puVar11 = puVar12 + 2;
              if (*(char *)((long)puVar12 + 0x27) < '\0') {
                func_0x00109e84(&uStack_5b0,*puVar11,puVar15[uVar14 * 6 + 3]);
              }
              else {
LAB_0152e098:
                uStack_5a8 = puVar11[1];
                uStack_5b0 = *puVar11;
                uStack_5a0 = puVar11[2];
              }
            }
            plStack_598 = (long *)puVar15[uVar14 * 6 + 5];
            uStack_520 = uStack_5c0;
            iStack_518 = (int)uStack_5b8;
            if ((long)uStack_500 < 0) {
              __ZdlPv(uStack_510);
            }
            uStack_508 = uStack_5a8;
            uStack_510 = uStack_5b0;
            uStack_500 = uStack_5a0;
            plStack_4f8 = plStack_598;
            if (((((int)uStack_520 != 0) && (uStack_520._4_4_ != 0)) && (iStack_518 != 0)) &&
               (plStack_598 != (long *)0x0)) {
              if (plStack_598 == plVar13) {
                if (__DEBUG_PROXY_CREATE != 0) {
                  func_0x005742a8("Proxy: Opened version [%s] at: %s");
                }
                uStack_5a0 = uStack_5a0 & 0xffffffffffffff00;
                uStack_5b8 = 0;
                uStack_5c0 = 0;
                uStack_5a8 = 0;
                uStack_5b0 = 0;
                uStack_590 = 0;
                plStack_598 = (long *)0x0;
                uStack_580 = 0;
                lStack_588 = 0;
                lStack_570 = 0;
                uStack_578 = 0;
                uStack_560 = 0;
                uStack_568 = 0;
                uStack_550 = 0;
                lStack_558 = 0;
                lStack_540 = 0;
                uStack_548 = 0;
                lStack_530 = 0;
                lStack_538 = 0;
                uStack_528 = 0;
                iVar6 = (**(code **)(*plVar13 + 0x20))(plVar13,&uStack_5c0,iStack_518,alStack_2b8);
                uStack_458 = 0;
                uStack_460 = 0;
                uStack_448 = 0;
                uStack_450 = 0;
                uStack_438 = 0;
                uStack_440 = 0;
                uStack_428 = 0;
                uStack_430 = 0;
                uStack_418 = 0;
                uStack_420 = 0;
                uStack_408 = 0;
                uStack_410 = 0;
                uStack_3f8 = 0;
                uStack_400 = 0;
                uStack_3e8 = 0;
                uStack_3f0 = 0;
                uStack_3e0 = 0;
                __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgENS_4fposI11__mbstate_tEE
                          (alStack_2b8,&uStack_460);
                if (iVar6 == 0) {
                  plVar9 = (long *)__Znwm(0xa0);
                  plVar9[1] = 0;
                  plVar9[2] = 0;
                  *plVar9 = (long)&
                                  PTR___ZNSt3__120__shared_ptr_emplaceIN5Proxy8LoadInfoENS_9allocatorIS2_EEED1Ev_01ffce60
                  ;
                  puVar15 = (ulong *)(plVar9 + 3);
                  *puVar15 = uStack_5c0;
                  plVar10 = plVar9 + 4;
                  plVar9[5] = 0;
                  *plVar10 = 0;
                  plVar9[0x11] = 0;
                  plVar9[0x10] = 0;
                  plVar9[0x13] = 0;
                  plVar9[0x12] = 0;
                  plVar9[7] = 0;
                  plVar9[6] = 0;
                  plVar9[9] = 0;
                  plVar9[8] = 0;
                  plVar9[0xb] = 0;
                  plVar9[10] = 0;
                  plVar9[0xd] = 0;
                  plVar9[0xc] = 0;
                  plVar9[0xf] = 0;
                  plVar9[0xe] = 0;
                  *(undefined1 *)(plVar9 + 0x13) = (undefined1)uStack_5a0;
                  if (uStack_520._4_4_ == 0) {
LAB_0152e354:
                    *param_1 = 0;
                    param_1[2] = 0;
                    param_1[3] = 0;
                    param_1[4] = 0;
                    param_1[5] = 0;
                    puVar7 = (undefined8 *)__Znwm(0x78);
                    puVar7[1] = 0;
                    puVar7[2] = 0;
                    *puVar7 = &
                              PTR___ZNSt3__120__shared_ptr_emplaceIN5Proxy4FileENS_9allocatorIS2_EEED1Ev_01ffceb0
                    ;
                    uStack_490 = uStack_520;
                    iStack_488 = iStack_518;
                    if ((long)uStack_500 < 0) {
                      func_0x00109e84(&uStack_480,uStack_510,uStack_508);
                    }
                    else {
                      uStack_478 = uStack_508;
                      uStack_480 = uStack_510;
                      uStack_470 = uStack_500;
                    }
                    plStack_468 = plStack_4f8;
                    if (lStack_4c8 < 0) {
                      func_0x00109e84(&pppppppuStack_4b0,pppppppuStack_4d8,uStack_4d0);
                    }
                    else {
                      uStack_4a8 = uStack_4d0;
                      pppppppuStack_4b0 = pppppppuStack_4d8;
                      lStack_4a0 = lStack_4c8;
                    }
                    plVar9[1] = plVar9[1] + 1;
                    puVar7[3] = plVar13;
                    puVar7[4] = uStack_490;
                    *(int *)(puVar7 + 5) = iStack_488;
                    puStack_4c0 = puVar15;
                    plStack_4b8 = plVar9;
                    if ((long)uStack_470 < 0) {
                      func_0x00109e84(puVar7 + 6,uStack_480,uStack_478);
                    }
                    else {
                      puVar7[7] = uStack_478;
                      puVar7[6] = uStack_480;
                      puVar7[8] = uStack_470;
                    }
                    lVar5 = lStack_4a0;
                    puVar7[9] = plStack_468;
                    puVar7[0xb] = uStack_4a8;
                    puVar7[10] = pppppppuStack_4b0;
                    pppppppuStack_4b0 = (undefined8 *******)0x0;
                    uStack_4a8 = 0;
                    lStack_4a0 = 0;
                    puVar7[0xc] = lVar5;
                    puVar7[0xd] = puVar15;
                    puVar7[0xe] = plVar9;
                    plVar13 = plVar9 + 1;
                    *plVar13 = *plVar13 + 1;
                    LOAcquire();
                    lVar5 = *plVar13;
                    *plVar13 = lVar5 + -1;
                    LORelease();
                    if (lVar5 == 0) {
                      (**(code **)(*plVar9 + 0x10))(plVar9);
                      __ZNSt3__119__shared_weak_count14__release_weakEv(plVar9);
                      if (lStack_4a0 < 0) {
                        __ZdlPv(pppppppuStack_4b0);
                      }
                    }
                    if ((long)uStack_470 < 0) {
                      __ZdlPv(uStack_480);
                      *(undefined8 **)(param_1 + 2) = puVar7 + 3;
                      *(undefined8 **)(param_1 + 4) = puVar7;
                    }
                    else {
                      *(undefined8 **)(param_1 + 2) = puVar7 + 3;
                      *(undefined8 **)(param_1 + 4) = puVar7;
                    }
                    if (plVar9 == (long *)0x0) goto LAB_0152e500;
                  }
                  else {
                    if (uStack_520._4_4_ == 1) {
                      func_0x01178448(plVar10,&plStack_598);
                      func_0x003144c0(plVar9 + 0x10,lStack_538,lStack_530,lStack_530 - lStack_538);
                      goto LAB_0152e354;
                    }
                    iVar6 = __ZN5Proxy8Metadata11DeserializeERS0_RKNSt3__16vectorIhNS2_9allocatorIhEEEEj
                                      (plVar10,(ulong)&uStack_5c0 | 8);
                    if (iVar6 == 0) goto LAB_0152e354;
                    *param_1 = iVar6;
                    param_1[2] = 0;
                    param_1[3] = 0;
                    param_1[4] = 0;
                    param_1[5] = 0;
                  }
                  LOAcquire();
                  lVar5 = plVar9[1];
                  plVar9[1] = lVar5 + -1;
                  LORelease();
                  if (lVar5 == 0) {
                    (**(code **)(*plVar9 + 0x10))(plVar9);
                    __ZNSt3__119__shared_weak_count14__release_weakEv(plVar9);
                  }
                }
                else {
                  *param_1 = iVar6;
                  param_1[2] = 0;
                  param_1[3] = 0;
                  param_1[4] = 0;
                  param_1[5] = 0;
                }
LAB_0152e500:
                if (lStack_538 != 0) {
                  lStack_530 = lStack_538;
                  __ZdlPv();
                }
                if (lStack_540 < 0) {
                  __ZdlPv(uStack_550);
                }
                if (lStack_558 < 0) {
                  __ZdlPv(uStack_568);
                }
                if (lStack_570 < 0) {
                  __ZdlPv(uStack_580);
                }
                if (lStack_588 < 0) {
                  __ZdlPv(plStack_598);
                }
                if (uStack_5b8 != 0) {
                  uStack_5b0 = uStack_5b8;
                  __ZdlPv();
                }
                goto LAB_0152e154;
              }
              func_0x00574348("Proxy: ignoring candidate backend: version [%s] has another backend")
              ;
            }
          }
        }
        puVar7 = puVar7 + 1;
      } while (puVar7 != puVar3);
    }
    *param_1 = 0x15;
    param_1[2] = 0;
    param_1[3] = 0;
    param_1[4] = 0;
    param_1[5] = 0;
LAB_0152e154:
    if ((long)uStack_500 < 0) {
      __ZdlPv(uStack_510);
    }
    if (puStack_4f0 != (undefined8 *)0x0) {
      __ZdlPv();
    }
  } while( true );
}


/* __ZNK5Proxy18ProxyContainer200617LoadGlobalVersionERjRNSt3__114basic_ifstreamIcNS2_11char_traitsIcEEEE @ 01530e6c */

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4
__ZNK5Proxy18ProxyContainer200617LoadGlobalVersionERjRNSt3__114basic_ifstreamIcNS2_11char_traitsIcEEEE
          (undefined8 param_1,undefined4 *param_2,long *param_3,long *param_4)

{
  code *pcVar1;
  int *piVar2;
  int extraout_w1;
  undefined8 *extraout_x1;
  undefined4 uVar3;
  int iVar4;
  uint uVar5;
  long lVar6;
  ulong uVar7;
  undefined8 uStack_170;
  undefined8 uStack_168;
  undefined8 uStack_160;
  int *piStack_158;
  long lStack_150;
  long lStack_148;
  undefined1 auStack_140 [12];
  int iStack_134;
  int iStack_130;
  undefined8 uStack_10c;
  byte bStack_ea;
  int iStack_e8;
  int iStack_e4;
  int iStack_e0;
  int iStack_dc;
  long lStack_d8;
  undefined1 auStack_90 [12];
  int iStack_84;
  undefined4 uStack_80;
  long lStack_28;

  lStack_28 = *(long *)PTR____stack_chk_guard_01d15188;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(param_3,auStack_90,0x68);
  if ((*(int *)((long)param_3 + *(long *)(*param_3 + -0x18) + 0x20) == 0) &&
     (iStack_84 == 0x6ca47 || iStack_84 == 0x1b432)) {
    uVar3 = 0;
    *param_2 = uStack_80;
    lVar6 = *(long *)PTR____stack_chk_guard_01d15188;
  }
  else {
    uVar3 = 0x15;
    lVar6 = *(long *)PTR____stack_chk_guard_01d15188;
  }
  if (lVar6 == lStack_28) {
    return uVar3;
  }
  ___stack_chk_fail(uVar3);
  if (extraout_w1 == 0) {
    __Unwind_Resume();
  }
  func_0x000e3a54();
  lStack_d8 = *(long *)PTR____stack_chk_guard_01d15188;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(param_4,auStack_140,0x68);
  if (*(int *)((long)param_4 + *(long *)(*param_4 + -0x18) + 0x20) == 0) {
    if (iStack_130 - 0x1dU < 0xfffffffe) {
      if ((__DEBUG_PROXY_CREATE != 0) || (4 < __DEBUG_TRACING)) {
        func_0x00574108("Proxy::checkHeader: unrecognized proxy version (version %i)");
      }
      uVar3 = 0x32;
      if (0x1a < iStack_130) {
        uVar3 = 0x15;
      }
    }
    else if (iStack_134 == 0x1b432) {
      uVar3 = 0x1e;
    }
    else {
      if (iStack_134 != 0x6ca47) {
        if ((__DEBUG_PROXY_CREATE != 0) || (4 < __DEBUG_TRACING)) {
          func_0x00574108("Proxy::checkHeader: unrecognized verification code (%i) for proxy");
        }
        goto LAB_01530fbc;
      }
      *extraout_x1 = uStack_10c;
      *(byte *)(extraout_x1 + 4) = bStack_ea & 1;
      if (iStack_e0 < 1) {
        uVar3 = 0x32;
      }
      else {
        piStack_158 = (int *)0x0;
        lStack_150 = 0;
        lStack_148 = 0;
        lVar6 = (long)iStack_e8;
        if (iStack_e8 != 0) {
          if (iStack_e8 < 0) goto LAB_0153135c;
          piVar2 = (int *)__Znwm(lVar6);
          _bzero(piVar2,lVar6);
          lStack_148 = (long)piVar2 + lVar6;
          piStack_158 = piVar2;
        }
        lVar6 = lStack_148;
        piVar2 = piStack_158;
        lStack_150 = lStack_148;
        __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgExNS_8ios_base7seekdirE
                  (param_4,(long)iStack_e4,0);
        if ((*(int *)((long)param_4 + *(long *)(*param_4 + -0x18) + 0x20) == 0) &&
           (__ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl
                      (param_4,piVar2,(long)iStack_e8),
           *(int *)((long)param_4 + *(long *)(*param_4 + -0x18) + 0x20) == 0)) {
          iVar4 = (int)((ulong)(lVar6 - (long)piVar2) >> 2);
          uVar5 = iVar4 - 1;
          if (0 < iVar4) {
            uVar7 = 0;
            if (8 < uVar5) {
              uVar5 = 9;
            }
            uVar5 = uVar5 + 1;
            do {
              if (piVar2[uVar7] < 0) {
                uVar5 = (uint)uVar7;
                break;
              }
              uVar7 = uVar7 + 1;
            } while (uVar5 != uVar7);
            if ((uVar5 < 4) ||
               ((ulong)(lVar6 - (long)piVar2) <
                (ulong)(long)(int)((int)*(undefined8 *)piVar2 +
                                   (int)((ulong)*(undefined8 *)piVar2 >> 0x20) +
                                   (int)*(undefined8 *)(piVar2 + 2) +
                                   (int)((ulong)*(undefined8 *)(piVar2 + 2) >> 0x20) +
                                   (uVar5 + 1) * 4 + 4))) {
              __ZdlPv(piVar2);
              uVar3 = 0x14;
            }
            else {
              func_0x001eb5a8(&uStack_170,piVar2 + (uVar5 + 1));
              if (*(char *)((long)extraout_x1 + 0x3f) < '\0') {
                __ZdlPv(extraout_x1[5]);
              }
              extraout_x1[6] = uStack_168;
              extraout_x1[5] = uStack_170;
              extraout_x1[7] = uStack_160;
              lVar6 = (long)(piVar2 + (uVar5 + 1)) + (long)*piVar2 + 1;
              func_0x001eb5a8(&uStack_170,lVar6);
              if (*(char *)((long)extraout_x1 + 0x57) < '\0') {
                __ZdlPv(extraout_x1[8]);
              }
              extraout_x1[9] = uStack_168;
              extraout_x1[8] = uStack_170;
              extraout_x1[10] = uStack_160;
              lVar6 = piVar2[1] + lVar6 + 1;
              func_0x001eb5a8(&uStack_170,lVar6);
              if (*(char *)((long)extraout_x1 + 0x6f) < '\0') {
                __ZdlPv(extraout_x1[0xb]);
              }
              extraout_x1[0xc] = uStack_168;
              extraout_x1[0xb] = uStack_170;
              extraout_x1[0xd] = uStack_160;
              func_0x001eb5a8(&uStack_170,piVar2[2] + lVar6 + 1);
              if (*(char *)((long)extraout_x1 + 0x87) < '\0') {
                __ZdlPv(extraout_x1[0xe]);
              }
              extraout_x1[0xf] = uStack_168;
              extraout_x1[0xe] = uStack_170;
              extraout_x1[0x10] = uStack_160;
              if (piStack_158 != (int *)0x0) {
                __ZdlPv();
              }
              func_0x00f9db28(extraout_x1 + 0x11,(long)iStack_e0);
              __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgExNS_8ios_base7seekdirE
                        (param_4,(long)iStack_dc,0);
              if (*(int *)((long)param_4 + *(long *)(*param_4 + -0x18) + 0x20) == 0) {
                __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl
                          (param_4,extraout_x1[0x11],(long)iStack_e0);
                uVar3 = 0;
                if (*(int *)((long)param_4 + *(long *)(*param_4 + -0x18) + 0x20) != 0) {
                  uVar3 = 0xd;
                }
              }
              else {
                uVar3 = 0xd;
              }
            }
            goto LAB_01531148;
          }
          uVar3 = 0x14;
        }
        else {
          uVar3 = 0xd;
        }
        if (piVar2 != (int *)0x0) {
          __ZdlPv(piVar2);
        }
      }
    }
  }
  else {
    if ((__DEBUG_PROXY_CREATE != 0) || (4 < __DEBUG_TRACING)) {
      func_0x00574108("Proxy::checkHeader: unable to read header for proxy");
    }
LAB_01530fbc:
    uVar3 = 0x15;
  }
LAB_01531148:
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_d8) {
    return uVar3;
  }
  ___stack_chk_fail();
LAB_0153135c:
  func_0x00108ee8(&piStack_158);
                    /* WARNING: Does not return */
  pcVar1 = (code *)SoftwareBreakpoint(1,0x1531368);
  (*pcVar1)();
}


/* __ZNK5Proxy18ProxyContainer200612LoadMetadataERNS_15BackendLoadInfoEjRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEE @ 01530f38 */

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4
__ZNK5Proxy18ProxyContainer200612LoadMetadataERNS_15BackendLoadInfoEjRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEE
          (undefined8 param_1,undefined8 *param_2,undefined8 param_3,long *param_4)

{
  code *pcVar1;
  int *piVar2;
  undefined4 uVar3;
  int iVar4;
  uint uVar5;
  ulong uVar6;
  long lVar7;
  undefined8 uStack_e0;
  undefined8 uStack_d8;
  undefined8 uStack_d0;
  int *piStack_c8;
  long lStack_c0;
  long lStack_b8;
  undefined1 auStack_b0 [12];
  int iStack_a4;
  int iStack_a0;
  undefined8 uStack_7c;
  byte bStack_5a;
  int iStack_58;
  int iStack_54;
  int iStack_50;
  int iStack_4c;
  long lStack_48;

  lStack_48 = *(long *)PTR____stack_chk_guard_01d15188;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(param_4,auStack_b0,0x68);
  if (*(int *)((long)param_4 + *(long *)(*param_4 + -0x18) + 0x20) == 0) {
    if (iStack_a0 - 0x1dU < 0xfffffffe) {
      if ((__DEBUG_PROXY_CREATE != 0) || (4 < __DEBUG_TRACING)) {
        func_0x00574108("Proxy::checkHeader: unrecognized proxy version (version %i)");
      }
      uVar3 = 0x32;
      if (0x1a < iStack_a0) {
        uVar3 = 0x15;
      }
    }
    else if (iStack_a4 == 0x1b432) {
      uVar3 = 0x1e;
    }
    else {
      if (iStack_a4 != 0x6ca47) {
        if ((__DEBUG_PROXY_CREATE != 0) || (4 < __DEBUG_TRACING)) {
          func_0x00574108("Proxy::checkHeader: unrecognized verification code (%i) for proxy");
        }
        goto LAB_01530fbc;
      }
      *param_2 = uStack_7c;
      *(byte *)(param_2 + 4) = bStack_5a & 1;
      if (iStack_50 < 1) {
        uVar3 = 0x32;
      }
      else {
        piStack_c8 = (int *)0x0;
        lStack_c0 = 0;
        lStack_b8 = 0;
        lVar7 = (long)iStack_58;
        if (iStack_58 != 0) {
          if (iStack_58 < 0) goto LAB_0153135c;
          piVar2 = (int *)__Znwm(lVar7);
          _bzero(piVar2,lVar7);
          lStack_b8 = (long)piVar2 + lVar7;
          piStack_c8 = piVar2;
        }
        lVar7 = lStack_b8;
        piVar2 = piStack_c8;
        lStack_c0 = lStack_b8;
        __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgExNS_8ios_base7seekdirE
                  (param_4,(long)iStack_54,0);
        if ((*(int *)((long)param_4 + *(long *)(*param_4 + -0x18) + 0x20) == 0) &&
           (__ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl
                      (param_4,piVar2,(long)iStack_58),
           *(int *)((long)param_4 + *(long *)(*param_4 + -0x18) + 0x20) == 0)) {
          iVar4 = (int)((ulong)(lVar7 - (long)piVar2) >> 2);
          uVar5 = iVar4 - 1;
          if (0 < iVar4) {
            uVar6 = 0;
            if (8 < uVar5) {
              uVar5 = 9;
            }
            uVar5 = uVar5 + 1;
            do {
              if (piVar2[uVar6] < 0) {
                uVar5 = (uint)uVar6;
                break;
              }
              uVar6 = uVar6 + 1;
            } while (uVar5 != uVar6);
            if ((uVar5 < 4) ||
               ((ulong)(lVar7 - (long)piVar2) <
                (ulong)(long)(int)((int)*(undefined8 *)piVar2 +
                                   (int)((ulong)*(undefined8 *)piVar2 >> 0x20) +
                                   (int)*(undefined8 *)(piVar2 + 2) +
                                   (int)((ulong)*(undefined8 *)(piVar2 + 2) >> 0x20) +
                                   (uVar5 + 1) * 4 + 4))) {
              __ZdlPv(piVar2);
              uVar3 = 0x14;
            }
            else {
              func_0x001eb5a8(&uStack_e0,piVar2 + (uVar5 + 1));
              if (*(char *)((long)param_2 + 0x3f) < '\0') {
                __ZdlPv(param_2[5]);
              }
              param_2[6] = uStack_d8;
              param_2[5] = uStack_e0;
              param_2[7] = uStack_d0;
              lVar7 = (long)(piVar2 + (uVar5 + 1)) + (long)*piVar2 + 1;
              func_0x001eb5a8(&uStack_e0,lVar7);
              if (*(char *)((long)param_2 + 0x57) < '\0') {
                __ZdlPv(param_2[8]);
              }
              param_2[9] = uStack_d8;
              param_2[8] = uStack_e0;
              param_2[10] = uStack_d0;
              lVar7 = piVar2[1] + lVar7 + 1;
              func_0x001eb5a8(&uStack_e0,lVar7);
              if (*(char *)((long)param_2 + 0x6f) < '\0') {
                __ZdlPv(param_2[0xb]);
              }
              param_2[0xc] = uStack_d8;
              param_2[0xb] = uStack_e0;
              param_2[0xd] = uStack_d0;
              func_0x001eb5a8(&uStack_e0,piVar2[2] + lVar7 + 1);
              if (*(char *)((long)param_2 + 0x87) < '\0') {
                __ZdlPv(param_2[0xe]);
              }
              param_2[0xf] = uStack_d8;
              param_2[0xe] = uStack_e0;
              param_2[0x10] = uStack_d0;
              if (piStack_c8 != (int *)0x0) {
                __ZdlPv();
              }
              func_0x00f9db28(param_2 + 0x11,(long)iStack_50);
              __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgExNS_8ios_base7seekdirE
                        (param_4,(long)iStack_4c,0);
              if (*(int *)((long)param_4 + *(long *)(*param_4 + -0x18) + 0x20) == 0) {
                __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl
                          (param_4,param_2[0x11],(long)iStack_50);
                uVar3 = 0;
                if (*(int *)((long)param_4 + *(long *)(*param_4 + -0x18) + 0x20) != 0) {
                  uVar3 = 0xd;
                }
              }
              else {
                uVar3 = 0xd;
              }
            }
            goto LAB_01531148;
          }
          uVar3 = 0x14;
        }
        else {
          uVar3 = 0xd;
        }
        if (piVar2 != (int *)0x0) {
          __ZdlPv(piVar2);
        }
      }
    }
  }
  else {
    if ((__DEBUG_PROXY_CREATE != 0) || (4 < __DEBUG_TRACING)) {
      func_0x00574108("Proxy::checkHeader: unable to read header for proxy");
    }
LAB_01530fbc:
    uVar3 = 0x15;
  }
LAB_01531148:
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_48) {
    return uVar3;
  }
  ___stack_chk_fail();
LAB_0153135c:
  func_0x00108ee8(&piStack_c8);
                    /* WARNING: Does not return */
  pcVar1 = (code *)SoftwareBreakpoint(1,0x1531368);
  (*pcVar1)();
}


/* __ZNK5Proxy18ProxyContainer20064SaveERNSt3__114basic_ofstreamIcNS1_11char_traitsIcEEEERNS_15BackendSaveInfoE @ 01531374 */

/* WARNING: Possible PIC construction at 0x01531684: Changing call to branch */
/* WARNING: Possible PIC construction at 0x015316e0: Changing call to branch */
/* WARNING: Possible PIC construction at 0x0153170c: Changing call to branch */
/* WARNING: Removing unreachable block (ram,0x015316e4) */
/* WARNING: Removing unreachable block (ram,0x01531704) */
/* WARNING: Removing unreachable block (ram,0x01531688) */
/* WARNING: Removing unreachable block (ram,0x015316b0) */
/* WARNING: Removing unreachable block (ram,0x015316c8) */
/* WARNING: Removing unreachable block (ram,0x01531710) */
/* WARNING: Removing unreachable block (ram,0x01531794) */
/* WARNING: Removing unreachable block (ram,0x015317b8) */
/* WARNING: Removing unreachable block (ram,0x015317e4) */

void __ZNK5Proxy18ProxyContainer20064SaveERNSt3__114basic_ofstreamIcNS1_11char_traitsIcEEEERNS_15BackendSaveInfoE
               (undefined8 param_1,long *param_2,long param_3)

{
  uint uVar1;
  uint uVar2;
  uint uVar3;
  int iVar4;
  undefined8 *puVar5;
  int extraout_w1;
  uint uVar6;
  long lVar7;
  long *plVar8;
  undefined1 auVar9 [16];
  undefined8 uStack_180;
  undefined8 uStack_178;
  ulong uStack_170;
  undefined8 uStack_168;
  undefined8 uStack_160;
  undefined8 uStack_158;
  undefined8 uStack_150;
  undefined8 uStack_148;
  undefined8 uStack_140;
  undefined8 uStack_138;
  undefined8 uStack_130;
  undefined8 uStack_128;
  undefined8 uStack_120;
  uint uStack_114;
  uint uStack_110;
  uint uStack_10c;
  uint uStack_108;
  undefined4 uStack_104;
  undefined8 auStack_100 [17];
  long lStack_78;

  lStack_78 = *(long *)PTR____stack_chk_guard_01d15188;
  uVar6 = 0x1b;
  if (*(char *)(param_3 + 0x28) != '\0') {
    uVar6 = 0x1c;
  }
  uStack_180 = 0;
  uStack_168 = 0;
  uStack_120 = 0;
  uStack_138 = 0;
  uStack_140 = 0;
  uStack_128 = 0;
  uStack_130 = 0;
  uStack_158 = 0;
  uStack_160 = 0;
  uStack_148 = 0;
  uStack_150 = 0;
  uStack_178 = 0x1b43200000000;
  uStack_170 = (ulong)uVar6;
  if ((*(byte *)((long)param_2 + *(long *)(*param_2 + -0x18) + 0x20) & 5) == 0) {
    plVar8 = *(long **)((long)param_2 + *(long *)(*param_2 + -0x18) + 0x28);
    (**(code **)(*plVar8 + 0x20))(auStack_100,plVar8,0,1,0x10);
  }
  __ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5writeEPKcl(param_2,&uStack_180,0x68);
  if (*(int *)((long)param_2 + *(long *)(*param_2 + -0x18) + 0x20) == 0) {
    __ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5flushEv(param_2);
    if (*(int *)((long)param_2 + *(long *)(*param_2 + -0x18) + 0x20) == 0) {
      uVar6 = *(uint *)(param_3 + 0x40);
      if (-1 < (char)*(byte *)(param_3 + 0x4f)) {
        uVar6 = (uint)*(byte *)(param_3 + 0x4f);
      }
      uVar1 = *(uint *)(param_3 + 0x58);
      if (-1 < (char)*(byte *)(param_3 + 0x67)) {
        uVar1 = (uint)*(byte *)(param_3 + 0x67);
      }
      uVar2 = *(uint *)(param_3 + 0x70);
      if (-1 < (char)*(byte *)(param_3 + 0x7f)) {
        uVar2 = (uint)*(byte *)(param_3 + 0x7f);
      }
      uVar3 = *(uint *)(param_3 + 0x88);
      if (-1 < (char)*(byte *)(param_3 + 0x97)) {
        uVar3 = (uint)*(byte *)(param_3 + 0x97);
      }
      uStack_104 = 0xffffffff;
      lVar7 = *(long *)(*param_2 + -0x18);
      uStack_114 = uVar6;
      uStack_110 = uVar1;
      uStack_10c = uVar2;
      uStack_108 = uVar3;
      if ((*(byte *)((long)param_2 + lVar7 + 0x20) & 5) == 0) {
        plVar8 = *(long **)((long)param_2 + lVar7 + 0x28);
        (**(code **)(*plVar8 + 0x20))(auStack_100,plVar8,0,1,0x10);
      }
      __ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5writeEPKcl(param_2,&uStack_114,0x14);
      if (*(int *)((long)param_2 + *(long *)(*param_2 + -0x18) + 0x20) == 0) {
        lVar7 = *(long *)(param_3 + 0x38);
        if (-1 < *(char *)(param_3 + 0x4f)) {
          lVar7 = param_3 + 0x38;
        }
        __ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5writeEPKcl
                  (param_2,lVar7,(long)(int)uStack_114 + 1);
        if (*(int *)((long)param_2 + *(long *)(*param_2 + -0x18) + 0x20) == 0) {
          lVar7 = *(long *)(param_3 + 0x50);
          if (-1 < *(char *)(param_3 + 0x67)) {
            lVar7 = param_3 + 0x50;
          }
          __ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5writeEPKcl
                    (param_2,lVar7,(long)(int)uStack_110 + 1);
          if (*(int *)((long)param_2 + *(long *)(*param_2 + -0x18) + 0x20) == 0) {
            lVar7 = *(long *)(param_3 + 0x68);
            if (-1 < *(char *)(param_3 + 0x7f)) {
              lVar7 = param_3 + 0x68;
            }
            __ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5writeEPKcl
                      (param_2,lVar7,(long)(int)uStack_10c + 1);
            if (*(int *)((long)param_2 + *(long *)(*param_2 + -0x18) + 0x20) == 0) {
              lVar7 = *(long *)(param_3 + 0x80);
              if (-1 < *(char *)(param_3 + 0x97)) {
                lVar7 = param_3 + 0x80;
              }
              __ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5writeEPKcl
                        (param_2,lVar7,(long)(int)uStack_108 + 1);
              if ((*(int *)((long)param_2 + *(long *)(*param_2 + -0x18) + 0x20) == 0) &&
                 (iVar4 = func_0x01530e10(param_2,uVar6 + uVar1 + uVar2 + uVar3 + 0x18), -1 < iVar4)
                 ) {
                if (*(long *)(param_3 + 0xa0) == *(long *)(param_3 + 0x98)) {
                  puVar5 = auStack_100;
                }
                else {
                  puVar5 = auStack_100;
                }
                goto __ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5tellpEv;
              }
            }
          }
        }
      }
    }
  }
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_78) {
    return;
  }
  ___stack_chk_fail(0x1d);
  if (extraout_w1 == 0) {
    __Unwind_Resume();
  }
  auVar9 = func_0x000e3a54();
  param_2 = auVar9._8_8_;
  puVar5 = auVar9._0_8_;
__ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5tellpEv:
  if ((*(byte *)((long)param_2 + *(long *)(*param_2 + -0x18) + 0x20) & 5) == 0) {
    plVar8 = *(long **)((long)param_2 + *(long *)(*param_2 + -0x18) + 0x28);
                    /* WARNING: Could not recover jumptable at 0x0153186c. Too many branches */
                    /* WARNING: Treating indirect jump as call */
    (**(code **)(*plVar8 + 0x20))(puVar5,plVar8,0,1,0x10);
    return;
  }
  puVar5[0xd] = 0;
  puVar5[0xc] = 0;
  puVar5[0xf] = 0;
  puVar5[0xe] = 0;
  puVar5[9] = 0;
  puVar5[8] = 0;
  puVar5[0xb] = 0;
  puVar5[10] = 0;
  puVar5[5] = 0;
  puVar5[4] = 0;
  puVar5[7] = 0;
  puVar5[6] = 0;
  puVar5[1] = 0;
  *puVar5 = 0;
  puVar5[3] = 0;
  puVar5[2] = 0;
  puVar5[0x10] = 0xffffffffffffffff;
  return;
}


/* __ZNK5Proxy18ProxyContainer200613LoadImageBestER12CImageBufferRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEEjj @ 01531968 */

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __ZNK5Proxy18ProxyContainer200613LoadImageBestER12CImageBufferRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEEjj
               (undefined8 param_1,undefined8 param_2,long *param_3,undefined8 param_4,
               undefined8 param_5,undefined8 param_6)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  undefined8 uVar6;
  int extraout_w1;
  long extraout_x1;
  section *psVar7;
  undefined1 auStack_268 [60];
  int iStack_22c;
  undefined1 auStack_200 [32];
  undefined1 uStack_1e0;
  undefined7 uStack_1df;
  char cStack_1c9;
  undefined1 auStack_1c0 [184];
  long lStack_108;
  undefined1 auStack_b0 [60];
  int iStack_74;
  long lStack_48;

  lStack_48 = *(long *)PTR____stack_chk_guard_01d15188;
  uVar6 = param_5;
  func_0x0074aff4();
  psVar7 = &section_00000068;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(param_3,auStack_b0);
  if (*(int *)((long)param_3 + *(long *)(*param_3 + -0x18) + 0x20) == 0) {
    psVar7 = (section *)0x0;
    __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgExNS_8ios_base7seekdirE
              (param_3,(long)iStack_74);
    if (*(int *)((long)param_3 + *(long *)(*param_3 + -0x18) + 0x20) == 0) {
      func_0x0074aff4();
      psVar7 = (section *)0x0;
      param_6 = 0;
      iVar5 = func_0x01534768(param_3,param_2,0,0,param_5,0);
      uVar6 = param_5;
      if (iVar5 != 0) {
        func_0x0074aff4();
        func_0x0074aff4();
        if (__DEBUG_DISK_LATENCY != 0) {
          func_0x00574108("Proxy load time: %i ms, unpack: %i ms.");
        }
        uVar6 = 0;
        if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_48) {
          return;
        }
        goto LAB_01531ae8;
      }
    }
    param_5 = uVar6;
    uVar6 = 0x15;
    if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_48) {
      return;
    }
  }
  else {
    if ((__DEBUG_PROXY_CREATE != 0) || (param_5 = uVar6, 4 < __DEBUG_TRACING)) {
      func_0x00574108("Proxy::loadPreview0: unable to read header for proxy");
      param_5 = uVar6;
    }
    uVar6 = 0x14;
    if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_48) {
      return;
    }
  }
LAB_01531ae8:
  ___stack_chk_fail(uVar6);
  if (extraout_w1 == 0) {
    __Unwind_Resume();
  }
  func_0x000e3a54();
  lStack_108 = *(long *)PTR____stack_chk_guard_01d15188;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(psVar7,auStack_268,0x68);
  if (*(int *)(psVar7->segname + *(long *)(*(long *)psVar7->sectname + -0x18) + 0x10) == 0) {
    __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgExNS_8ios_base7seekdirE
              (psVar7,(long)iStack_22c,0);
    if (*(int *)(psVar7->segname + *(long *)(*(long *)psVar7->sectname + -0x18) + 0x10) == 0) {
      func_0x0074aff4();
      iVar5 = func_0x01534768(psVar7,extraout_x1,param_5,param_5,param_6,1);
      if (iVar5 != 0) {
        if (__DEBUG_DISK_LATENCY != 0) {
          func_0x0074aff4();
          func_0x00574108("Time spent loading thumbnail: %i ms [%i x %i].");
        }
        iVar5 = *(int *)(extraout_x1 + 0x20);
        iVar2 = *(int *)(extraout_x1 + 0x24);
        if (0x20f58 < iVar2 * iVar5) {
          iVar1 = iVar2;
          if (iVar2 < 0) {
            iVar1 = iVar2 + 1;
          }
          iVar3 = 0;
          if (iVar2 != 0) {
            iVar3 = (iVar5 * 0x1c2 + (iVar1 >> 1)) / iVar2;
          }
          iVar1 = iVar5;
          if (iVar5 < 0) {
            iVar1 = iVar5 + 1;
          }
          if (iVar2 < iVar5) {
            iVar3 = 0x1c2;
          }
          iVar4 = 0;
          if (iVar5 != 0) {
            iVar4 = (iVar2 * 0x1c2 + (iVar1 >> 1)) / iVar5;
          }
          iVar1 = 0x1c2;
          if (iVar2 < iVar5) {
            iVar1 = iVar4;
          }
          func_0x011947c8(auStack_1c0);
          func_0x01195d64(auStack_1c0,iVar3,iVar1,0,3,0x10);
          func_0x0117103c(&uStack_1e0,extraout_x1);
          func_0x0117103c(auStack_200,auStack_1c0);
          func_0x0061f644(&uStack_1e0,auStack_200);
          func_0x01195d64(extraout_x1,iVar3,iVar1,param_6,3,0x10);
          cStack_1c9 = '\0';
          uStack_1e0 = 0;
          func_0x01198370(extraout_x1,auStack_1c0,0,&uStack_1e0);
          if (cStack_1c9 < '\0') {
            __ZdlPv(CONCAT71(uStack_1df,uStack_1e0));
          }
          func_0x01194dbc(auStack_1c0);
        }
        uVar6 = 0;
        if (*(long *)PTR____stack_chk_guard_01d15188 != lStack_108) goto LAB_01531d08;
        return;
      }
    }
  }
  else if ((__DEBUG_PROXY_CREATE != 0) || (4 < __DEBUG_TRACING)) {
    func_0x00574108("Proxy::loadThumb: unable to read header for proxy");
  }
  while (uVar6 = 0x15, *(long *)PTR____stack_chk_guard_01d15188 != lStack_108) {
LAB_01531d08:
    ___stack_chk_fail(uVar6);
  }
  return;
}


/* __ZNK5Proxy18ProxyContainer200613LoadImageFastER12CImageBufferRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEEjjj @ 01531af8 */

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __ZNK5Proxy18ProxyContainer200613LoadImageFastER12CImageBufferRNSt3__114basic_ifstreamIcNS3_11char_traitsIcEEEEjjj
               (undefined8 param_1,long param_2,long *param_3,undefined8 param_4,undefined8 param_5,
               undefined8 param_6)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  undefined8 uVar6;
  undefined1 auStack_1a8 [60];
  int iStack_16c;
  undefined1 auStack_140 [32];
  undefined1 uStack_120;
  undefined7 uStack_11f;
  char cStack_109;
  undefined1 auStack_100 [184];
  long lStack_48;

  lStack_48 = *(long *)PTR____stack_chk_guard_01d15188;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(param_3,auStack_1a8,0x68);
  if (*(int *)((long)param_3 + *(long *)(*param_3 + -0x18) + 0x20) == 0) {
    __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE5seekgExNS_8ios_base7seekdirE
              (param_3,(long)iStack_16c,0);
    if (*(int *)((long)param_3 + *(long *)(*param_3 + -0x18) + 0x20) == 0) {
      func_0x0074aff4();
      iVar5 = func_0x01534768(param_3,param_2,param_5,param_5,param_6,1);
      if (iVar5 != 0) {
        if (__DEBUG_DISK_LATENCY != 0) {
          func_0x0074aff4();
          func_0x00574108("Time spent loading thumbnail: %i ms [%i x %i].");
        }
        iVar5 = *(int *)(param_2 + 0x20);
        iVar2 = *(int *)(param_2 + 0x24);
        if (0x20f58 < iVar2 * iVar5) {
          iVar1 = iVar2;
          if (iVar2 < 0) {
            iVar1 = iVar2 + 1;
          }
          iVar3 = 0;
          if (iVar2 != 0) {
            iVar3 = (iVar5 * 0x1c2 + (iVar1 >> 1)) / iVar2;
          }
          iVar1 = iVar5;
          if (iVar5 < 0) {
            iVar1 = iVar5 + 1;
          }
          if (iVar2 < iVar5) {
            iVar3 = 0x1c2;
          }
          iVar4 = 0;
          if (iVar5 != 0) {
            iVar4 = (iVar2 * 0x1c2 + (iVar1 >> 1)) / iVar5;
          }
          iVar1 = 0x1c2;
          if (iVar2 < iVar5) {
            iVar1 = iVar4;
          }
          func_0x011947c8(auStack_100);
          func_0x01195d64(auStack_100,iVar3,iVar1,0,3,0x10);
          func_0x0117103c(&uStack_120,param_2);
          func_0x0117103c(auStack_140,auStack_100);
          func_0x0061f644(&uStack_120,auStack_140);
          func_0x01195d64(param_2,iVar3,iVar1,param_6,3,0x10);
          cStack_109 = '\0';
          uStack_120 = 0;
          func_0x01198370(param_2,auStack_100,0,&uStack_120);
          if (cStack_109 < '\0') {
            __ZdlPv(CONCAT71(uStack_11f,uStack_120));
          }
          func_0x01194dbc(auStack_100);
        }
        uVar6 = 0;
        if (*(long *)PTR____stack_chk_guard_01d15188 != lStack_48) goto LAB_01531d08;
        return;
      }
    }
  }
  else if ((__DEBUG_PROXY_CREATE != 0) || (4 < __DEBUG_TRACING)) {
    func_0x00574108("Proxy::loadThumb: unable to read header for proxy");
  }
  while (uVar6 = 0x15, *(long *)PTR____stack_chk_guard_01d15188 != lStack_48) {
LAB_01531d08:
    ___stack_chk_fail(uVar6);
  }
  return;
}


/* __ZN5Proxy18ProxyContainer2006D1Ev @ 01531d4c */

void __ZN5Proxy18ProxyContainer2006D1Ev(void)

{
  return;
}


/* __ZN5Proxy18ProxyContainer2006D0Ev @ 01531d50 */

void __ZN5Proxy18ProxyContainer2006D0Ev(void)

{
                    /* WARNING: Could not recover jumptable at 0x0156fe64. Too many branches */
                    /* WARNING: Treating indirect jump as call */
  (*(code *)PTR___ZdlPv_01d15060)();
  return;
}


/* __ZN5Proxy14SaveSturdyJPEGERNSt3__114basic_ofstreamIcNS0_11char_traitsIcEEEER12CImageBufferjbb @ 01531d54 */

/* WARNING: Possible PIC construction at 0x0153321c: Changing call to branch */
/* WARNING: Possible PIC construction at 0x01533294: Changing call to branch */
/* WARNING: Possible PIC construction at 0x015332f4: Changing call to branch */
/* WARNING: Possible PIC construction at 0x01533324: Changing call to branch */
/* WARNING: Possible PIC construction at 0x01533358: Changing call to branch */
/* WARNING: Possible PIC construction at 0x015335d4: Changing call to branch */
/* WARNING: Possible PIC construction at 0x01533614: Changing call to branch */
/* WARNING: Possible PIC construction at 0x01536650: Changing call to branch */
/* WARNING: Possible PIC construction at 0x015376ec: Changing call to branch */
/* WARNING: Possible PIC construction at 0x01537350: Changing call to branch */
/* WARNING: Possible PIC construction at 0x01534f18: Changing call to branch */
/* WARNING: Possible PIC construction at 0x01534f6c: Changing call to branch */
/* WARNING: Possible PIC construction at 0x01534fa4: Changing call to branch */
/* WARNING: Removing unreachable block (ram,0x01537354) */
/* WARNING: Removing unreachable block (ram,0x01537360) */
/* WARNING: Removing unreachable block (ram,0x015376f0) */
/* WARNING: Removing unreachable block (ram,0x0153771c) */
/* WARNING: Removing unreachable block (ram,0x015376f4) */
/* WARNING: Removing unreachable block (ram,0x01537704) */
/* WARNING: Removing unreachable block (ram,0x01536654) */
/* WARNING: Removing unreachable block (ram,0x01537078) */
/* WARNING: Removing unreachable block (ram,0x01536658) */
/* WARNING: Removing unreachable block (ram,0x0153669c) */
/* WARNING: Removing unreachable block (ram,0x01536720) */
/* WARNING: Removing unreachable block (ram,0x01536758) */
/* WARNING: Removing unreachable block (ram,0x01536794) */
/* WARNING: Removing unreachable block (ram,0x01536854) */
/* WARNING: Removing unreachable block (ram,0x01536860) */
/* WARNING: Removing unreachable block (ram,0x0153687c) */
/* WARNING: Removing unreachable block (ram,0x015368cc) */
/* WARNING: Removing unreachable block (ram,0x015368fc) */
/* WARNING: Removing unreachable block (ram,0x0153697c) */
/* WARNING: Removing unreachable block (ram,0x01536984) */
/* WARNING: Removing unreachable block (ram,0x01536884) */
/* WARNING: Removing unreachable block (ram,0x0153698c) */
/* WARNING: Removing unreachable block (ram,0x01536994) */
/* WARNING: Removing unreachable block (ram,0x015369b4) */
/* WARNING: Removing unreachable block (ram,0x015369b8) */
/* WARNING: Removing unreachable block (ram,0x0153679c) */
/* WARNING: Removing unreachable block (ram,0x01536760) */
/* WARNING: Removing unreachable block (ram,0x01536790) */
/* WARNING: Removing unreachable block (ram,0x01536734) */
/* WARNING: Removing unreachable block (ram,0x015367d4) */
/* WARNING: Removing unreachable block (ram,0x01536810) */
/* WARNING: Removing unreachable block (ram,0x01536890) */
/* WARNING: Removing unreachable block (ram,0x0153689c) */
/* WARNING: Removing unreachable block (ram,0x015368b8) */
/* WARNING: Removing unreachable block (ram,0x01536a20) */
/* WARNING: Removing unreachable block (ram,0x01536a50) */
/* WARNING: Removing unreachable block (ram,0x01536ad0) */
/* WARNING: Removing unreachable block (ram,0x01536ad8) */
/* WARNING: Removing unreachable block (ram,0x015368c0) */
/* WARNING: Removing unreachable block (ram,0x01536ae0) */
/* WARNING: Removing unreachable block (ram,0x01536ae8) */
/* WARNING: Removing unreachable block (ram,0x01536b08) */
/* WARNING: Removing unreachable block (ram,0x01536b0c) */
/* WARNING: Removing unreachable block (ram,0x01536818) */
/* WARNING: Removing unreachable block (ram,0x01536850) */
/* WARNING: Removing unreachable block (ram,0x015367dc) */
/* WARNING: Removing unreachable block (ram,0x0153680c) */
/* WARNING: Removing unreachable block (ram,0x01536754) */
/* WARNING: Removing unreachable block (ram,0x015369dc) */
/* WARNING: Removing unreachable block (ram,0x01536b30) */
/* WARNING: Removing unreachable block (ram,0x01536b6c) */
/* WARNING: Removing unreachable block (ram,0x01536c2c) */
/* WARNING: Removing unreachable block (ram,0x01536c38) */
/* WARNING: Removing unreachable block (ram,0x01536c54) */
/* WARNING: Removing unreachable block (ram,0x01536ca4) */
/* WARNING: Removing unreachable block (ram,0x01536cd4) */
/* WARNING: Removing unreachable block (ram,0x01536d54) */
/* WARNING: Removing unreachable block (ram,0x01536d5c) */
/* WARNING: Removing unreachable block (ram,0x01536c5c) */
/* WARNING: Removing unreachable block (ram,0x01536d64) */
/* WARNING: Removing unreachable block (ram,0x01536d6c) */
/* WARNING: Removing unreachable block (ram,0x01536d8c) */
/* WARNING: Removing unreachable block (ram,0x01536d90) */
/* WARNING: Removing unreachable block (ram,0x01536b74) */
/* WARNING: Removing unreachable block (ram,0x01536b38) */
/* WARNING: Removing unreachable block (ram,0x01536b68) */
/* WARNING: Removing unreachable block (ram,0x015369fc) */
/* WARNING: Removing unreachable block (ram,0x01536bac) */
/* WARNING: Removing unreachable block (ram,0x01536be8) */
/* WARNING: Removing unreachable block (ram,0x01536c68) */
/* WARNING: Removing unreachable block (ram,0x01536c74) */
/* WARNING: Removing unreachable block (ram,0x01536c90) */
/* WARNING: Removing unreachable block (ram,0x01536dd8) */
/* WARNING: Removing unreachable block (ram,0x01536e08) */
/* WARNING: Removing unreachable block (ram,0x01536e88) */
/* WARNING: Removing unreachable block (ram,0x01536e90) */
/* WARNING: Removing unreachable block (ram,0x01536c98) */
/* WARNING: Removing unreachable block (ram,0x01536e98) */
/* WARNING: Removing unreachable block (ram,0x01536ea0) */
/* WARNING: Removing unreachable block (ram,0x01536ec0) */
/* WARNING: Removing unreachable block (ram,0x01536ec4) */
/* WARNING: Removing unreachable block (ram,0x01536bf0) */
/* WARNING: Removing unreachable block (ram,0x01536c28) */
/* WARNING: Removing unreachable block (ram,0x01536bb4) */
/* WARNING: Removing unreachable block (ram,0x01536be4) */
/* WARNING: Removing unreachable block (ram,0x01536a1c) */
/* WARNING: Removing unreachable block (ram,0x01536db4) */
/* WARNING: Removing unreachable block (ram,0x01536708) */
/* WARNING: Removing unreachable block (ram,0x01536dd4) */
/* WARNING: Removing unreachable block (ram,0x01536ee8) */
/* WARNING: Removing unreachable block (ram,0x01536f0c) */
/* WARNING: Removing unreachable block (ram,0x01536f38) */
/* WARNING: Removing unreachable block (ram,0x01536f44) */
/* WARNING: Removing unreachable block (ram,0x01536f60) */
/* WARNING: Removing unreachable block (ram,0x01536f74) */
/* WARNING: Removing unreachable block (ram,0x01536fa4) */
/* WARNING: Removing unreachable block (ram,0x01537024) */
/* WARNING: Removing unreachable block (ram,0x0153702c) */
/* WARNING: Removing unreachable block (ram,0x01536f68) */
/* WARNING: Removing unreachable block (ram,0x01537034) */
/* WARNING: Removing unreachable block (ram,0x0153703c) */
/* WARNING: Removing unreachable block (ram,0x0153705c) */
/* WARNING: Removing unreachable block (ram,0x01537060) */
/* WARNING: Removing unreachable block (ram,0x01536f14) */
/* WARNING: Removing unreachable block (ram,0x01536ef0) */
/* WARNING: Removing unreachable block (ram,0x01536710) */
/* WARNING: Removing unreachable block (ram,0x01537084) */
/* WARNING: Removing unreachable block (ram,0x0153708c) */
/* WARNING: Removing unreachable block (ram,0x015370c0) */
/* WARNING: Removing unreachable block (ram,0x0153709c) */
/* WARNING: Removing unreachable block (ram,0x015370bc) */
/* WARNING: Removing unreachable block (ram,0x015370c4) */
/* WARNING: Removing unreachable block (ram,0x01533618) */
/* WARNING: Removing unreachable block (ram,0x0153361c) */
/* WARNING: Removing unreachable block (ram,0x015343d0) */
/* WARNING: Removing unreachable block (ram,0x01533634) */
/* WARNING: Removing unreachable block (ram,0x015343e4) */
/* WARNING: Removing unreachable block (ram,0x01533658) */
/* WARNING: Removing unreachable block (ram,0x015336ac) */
/* WARNING: Removing unreachable block (ram,0x0153370c) */
/* WARNING: Removing unreachable block (ram,0x01533738) */
/* WARNING: Removing unreachable block (ram,0x015338f0) */
/* WARNING: Removing unreachable block (ram,0x0153393c) */
/* WARNING: Removing unreachable block (ram,0x01533910) */
/* WARNING: Removing unreachable block (ram,0x0153394c) */
/* WARNING: Removing unreachable block (ram,0x01533924) */
/* WARNING: Removing unreachable block (ram,0x01533938) */
/* WARNING: Removing unreachable block (ram,0x01533960) */
/* WARNING: Removing unreachable block (ram,0x0153396c) */
/* WARNING: Removing unreachable block (ram,0x01533970) */
/* WARNING: Removing unreachable block (ram,0x01533984) */
/* WARNING: Removing unreachable block (ram,0x01533988) */
/* WARNING: Removing unreachable block (ram,0x01533990) */
/* WARNING: Removing unreachable block (ram,0x0153399c) */
/* WARNING: Removing unreachable block (ram,0x015339a0) */
/* WARNING: Removing unreachable block (ram,0x015339a8) */
/* WARNING: Removing unreachable block (ram,0x015339b8) */
/* WARNING: Removing unreachable block (ram,0x015339c0) */
/* WARNING: Removing unreachable block (ram,0x015339d4) */
/* WARNING: Removing unreachable block (ram,0x015339d8) */
/* WARNING: Removing unreachable block (ram,0x015339e0) */
/* WARNING: Removing unreachable block (ram,0x015339ec) */
/* WARNING: Removing unreachable block (ram,0x015339f0) */
/* WARNING: Removing unreachable block (ram,0x015339f8) */
/* WARNING: Removing unreachable block (ram,0x01533a08) */
/* WARNING: Removing unreachable block (ram,0x01533a10) */
/* WARNING: Removing unreachable block (ram,0x01533a24) */
/* WARNING: Removing unreachable block (ram,0x01533a28) */
/* WARNING: Removing unreachable block (ram,0x01533a30) */
/* WARNING: Removing unreachable block (ram,0x01533a3c) */
/* WARNING: Removing unreachable block (ram,0x01533a40) */
/* WARNING: Removing unreachable block (ram,0x01533774) */
/* WARNING: Removing unreachable block (ram,0x015337b0) */
/* WARNING: Removing unreachable block (ram,0x015337b8) */
/* WARNING: Removing unreachable block (ram,0x015337c0) */
/* WARNING: Removing unreachable block (ram,0x015337d8) */
/* WARNING: Removing unreachable block (ram,0x015337dc) */
/* WARNING: Removing unreachable block (ram,0x015337e4) */
/* WARNING: Removing unreachable block (ram,0x015337f0) */
/* WARNING: Removing unreachable block (ram,0x015337f4) */
/* WARNING: Removing unreachable block (ram,0x015337fc) */
/* WARNING: Removing unreachable block (ram,0x01533804) */
/* WARNING: Removing unreachable block (ram,0x0153380c) */
/* WARNING: Removing unreachable block (ram,0x01533820) */
/* WARNING: Removing unreachable block (ram,0x01533824) */
/* WARNING: Removing unreachable block (ram,0x0153382c) */
/* WARNING: Removing unreachable block (ram,0x01533838) */
/* WARNING: Removing unreachable block (ram,0x0153383c) */
/* WARNING: Removing unreachable block (ram,0x01533844) */
/* WARNING: Removing unreachable block (ram,0x0153384c) */
/* WARNING: Removing unreachable block (ram,0x01533854) */
/* WARNING: Removing unreachable block (ram,0x0153386c) */
/* WARNING: Removing unreachable block (ram,0x01533870) */
/* WARNING: Removing unreachable block (ram,0x01533878) */
/* WARNING: Removing unreachable block (ram,0x01533884) */
/* WARNING: Removing unreachable block (ram,0x01533888) */
/* WARNING: Removing unreachable block (ram,0x01533890) */
/* WARNING: Removing unreachable block (ram,0x01533898) */
/* WARNING: Removing unreachable block (ram,0x015338a0) */
/* WARNING: Removing unreachable block (ram,0x015338c8) */
/* WARNING: Removing unreachable block (ram,0x015338cc) */
/* WARNING: Removing unreachable block (ram,0x015338b8) */
/* WARNING: Removing unreachable block (ram,0x015338c4) */
/* WARNING: Removing unreachable block (ram,0x015338e0) */
/* WARNING: Removing unreachable block (ram,0x015338e4) */
/* WARNING: Removing unreachable block (ram,0x015337a0) */
/* WARNING: Removing unreachable block (ram,0x01533720) */
/* WARNING: Removing unreachable block (ram,0x01533a4c) */
/* WARNING: Removing unreachable block (ram,0x01533a64) */
/* WARNING: Removing unreachable block (ram,0x01533a78) */
/* WARNING: Removing unreachable block (ram,0x01533a98) */
/* WARNING: Removing unreachable block (ram,0x01533a9c) */
/* WARNING: Removing unreachable block (ram,0x01533aac) */
/* WARNING: Removing unreachable block (ram,0x01533ab0) */
/* WARNING: Removing unreachable block (ram,0x01533adc) */
/* WARNING: Removing unreachable block (ram,0x01533ae0) */
/* WARNING: Removing unreachable block (ram,0x01533ae8) */
/* WARNING: Removing unreachable block (ram,0x01533aec) */
/* WARNING: Removing unreachable block (ram,0x01533af4) */
/* WARNING: Removing unreachable block (ram,0x01533b24) */
/* WARNING: Removing unreachable block (ram,0x01533b28) */
/* WARNING: Removing unreachable block (ram,0x01533b38) */
/* WARNING: Removing unreachable block (ram,0x01533b54) */
/* WARNING: Removing unreachable block (ram,0x01533b5c) */
/* WARNING: Removing unreachable block (ram,0x01533b60) */
/* WARNING: Removing unreachable block (ram,0x01533b68) */
/* WARNING: Removing unreachable block (ram,0x01533b70) */
/* WARNING: Removing unreachable block (ram,0x01533b84) */
/* WARNING: Removing unreachable block (ram,0x01533b90) */
/* WARNING: Removing unreachable block (ram,0x01533b98) */
/* WARNING: Removing unreachable block (ram,0x01533b9c) */
/* WARNING: Removing unreachable block (ram,0x01533ba4) */
/* WARNING: Removing unreachable block (ram,0x01533bac) */
/* WARNING: Removing unreachable block (ram,0x01533bbc) */
/* WARNING: Removing unreachable block (ram,0x01533bc4) */
/* WARNING: Removing unreachable block (ram,0x01533bcc) */
/* WARNING: Removing unreachable block (ram,0x01533bd0) */
/* WARNING: Removing unreachable block (ram,0x01533bd8) */
/* WARNING: Removing unreachable block (ram,0x01533be0) */
/* WARNING: Removing unreachable block (ram,0x01533bf0) */
/* WARNING: Removing unreachable block (ram,0x01533bf8) */
/* WARNING: Removing unreachable block (ram,0x01533c04) */
/* WARNING: Removing unreachable block (ram,0x01533c0c) */
/* WARNING: Removing unreachable block (ram,0x01533c1c) */
/* WARNING: Removing unreachable block (ram,0x01533c28) */
/* WARNING: Removing unreachable block (ram,0x01533c34) */
/* WARNING: Removing unreachable block (ram,0x01533c40) */
/* WARNING: Removing unreachable block (ram,0x01533c4c) */
/* WARNING: Removing unreachable block (ram,0x01533c58) */
/* WARNING: Removing unreachable block (ram,0x01533c64) */
/* WARNING: Removing unreachable block (ram,0x015336d0) */
/* WARNING: Removing unreachable block (ram,0x01533c6c) */
/* WARNING: Removing unreachable block (ram,0x01533cc0) */
/* WARNING: Removing unreachable block (ram,0x01533c88) */
/* WARNING: Removing unreachable block (ram,0x01533cfc) */
/* WARNING: Removing unreachable block (ram,0x01533d20) */
/* WARNING: Removing unreachable block (ram,0x01533d50) */
/* WARNING: Removing unreachable block (ram,0x01533d5c) */
/* WARNING: Removing unreachable block (ram,0x01533d78) */
/* WARNING: Removing unreachable block (ram,0x01533d8c) */
/* WARNING: Removing unreachable block (ram,0x01533dc0) */
/* WARNING: Removing unreachable block (ram,0x01533e40) */
/* WARNING: Removing unreachable block (ram,0x01533e48) */
/* WARNING: Removing unreachable block (ram,0x01533d80) */
/* WARNING: Removing unreachable block (ram,0x01533e50) */
/* WARNING: Removing unreachable block (ram,0x01533e58) */
/* WARNING: Removing unreachable block (ram,0x01533e78) */
/* WARNING: Removing unreachable block (ram,0x01533e7c) */
/* WARNING: Removing unreachable block (ram,0x01533d28) */
/* WARNING: Removing unreachable block (ram,0x01533d04) */
/* WARNING: Removing unreachable block (ram,0x01533cb4) */
/* WARNING: Removing unreachable block (ram,0x01533e8c) */
/* WARNING: Removing unreachable block (ram,0x01533ce8) */
/* WARNING: Removing unreachable block (ram,0x01533ea8) */
/* WARNING: Removing unreachable block (ram,0x01533cf4) */
/* WARNING: Removing unreachable block (ram,0x01533eb8) */
/* WARNING: Removing unreachable block (ram,0x01533ec4) */
/* WARNING: Removing unreachable block (ram,0x01533ee8) */
/* WARNING: Removing unreachable block (ram,0x01533f08) */
/* WARNING: Removing unreachable block (ram,0x01533f1c) */
/* WARNING: Removing unreachable block (ram,0x01533f20) */
/* WARNING: Removing unreachable block (ram,0x01533f30) */
/* WARNING: Removing unreachable block (ram,0x0153422c) */
/* WARNING: Removing unreachable block (ram,0x01533f40) */
/* WARNING: Removing unreachable block (ram,0x01534244) */
/* WARNING: Removing unreachable block (ram,0x0153425c) */
/* WARNING: Removing unreachable block (ram,0x01533f54) */
/* WARNING: Removing unreachable block (ram,0x01533f68) */
/* WARNING: Removing unreachable block (ram,0x01533f6c) */
/* WARNING: Removing unreachable block (ram,0x01533f7c) */
/* WARNING: Removing unreachable block (ram,0x01533f90) */
/* WARNING: Removing unreachable block (ram,0x01533f94) */
/* WARNING: Removing unreachable block (ram,0x01533f9c) */
/* WARNING: Removing unreachable block (ram,0x01534294) */
/* WARNING: Removing unreachable block (ram,0x01533fac) */
/* WARNING: Removing unreachable block (ram,0x015342ac) */
/* WARNING: Removing unreachable block (ram,0x015342c4) */
/* WARNING: Removing unreachable block (ram,0x01533fc0) */
/* WARNING: Removing unreachable block (ram,0x01533fd4) */
/* WARNING: Removing unreachable block (ram,0x01533fd8) */
/* WARNING: Removing unreachable block (ram,0x01533ff0) */
/* WARNING: Removing unreachable block (ram,0x01533ff4) */
/* WARNING: Removing unreachable block (ram,0x01533ffc) */
/* WARNING: Removing unreachable block (ram,0x015342c8) */
/* WARNING: Removing unreachable block (ram,0x0153400c) */
/* WARNING: Removing unreachable block (ram,0x015342e0) */
/* WARNING: Removing unreachable block (ram,0x015342f8) */
/* WARNING: Removing unreachable block (ram,0x01534020) */
/* WARNING: Removing unreachable block (ram,0x01534034) */
/* WARNING: Removing unreachable block (ram,0x01534038) */
/* WARNING: Removing unreachable block (ram,0x01534050) */
/* WARNING: Removing unreachable block (ram,0x01534054) */
/* WARNING: Removing unreachable block (ram,0x0153405c) */
/* WARNING: Removing unreachable block (ram,0x015342fc) */
/* WARNING: Removing unreachable block (ram,0x0153406c) */
/* WARNING: Removing unreachable block (ram,0x01534314) */
/* WARNING: Removing unreachable block (ram,0x0153432c) */
/* WARNING: Removing unreachable block (ram,0x01534080) */
/* WARNING: Removing unreachable block (ram,0x01534094) */
/* WARNING: Removing unreachable block (ram,0x01534098) */
/* WARNING: Removing unreachable block (ram,0x0153409c) */
/* WARNING: Removing unreachable block (ram,0x015340b0) */
/* WARNING: Removing unreachable block (ram,0x015340b4) */
/* WARNING: Removing unreachable block (ram,0x015340c4) */
/* WARNING: Removing unreachable block (ram,0x01534260) */
/* WARNING: Removing unreachable block (ram,0x015340d4) */
/* WARNING: Removing unreachable block (ram,0x01534278) */
/* WARNING: Removing unreachable block (ram,0x01534290) */
/* WARNING: Removing unreachable block (ram,0x015340e8) */
/* WARNING: Removing unreachable block (ram,0x015340fc) */
/* WARNING: Removing unreachable block (ram,0x01534100) */
/* WARNING: Removing unreachable block (ram,0x01534110) */
/* WARNING: Removing unreachable block (ram,0x01534124) */
/* WARNING: Removing unreachable block (ram,0x01534128) */
/* WARNING: Removing unreachable block (ram,0x01534130) */
/* WARNING: Removing unreachable block (ram,0x01534330) */
/* WARNING: Removing unreachable block (ram,0x01534140) */
/* WARNING: Removing unreachable block (ram,0x01534348) */
/* WARNING: Removing unreachable block (ram,0x01534360) */
/* WARNING: Removing unreachable block (ram,0x01534154) */
/* WARNING: Removing unreachable block (ram,0x01534168) */
/* WARNING: Removing unreachable block (ram,0x0153416c) */
/* WARNING: Removing unreachable block (ram,0x01534184) */
/* WARNING: Removing unreachable block (ram,0x01534188) */
/* WARNING: Removing unreachable block (ram,0x01534190) */
/* WARNING: Removing unreachable block (ram,0x01534364) */
/* WARNING: Removing unreachable block (ram,0x015341a0) */
/* WARNING: Removing unreachable block (ram,0x0153437c) */
/* WARNING: Removing unreachable block (ram,0x01534394) */
/* WARNING: Removing unreachable block (ram,0x015341b4) */
/* WARNING: Removing unreachable block (ram,0x015341c8) */
/* WARNING: Removing unreachable block (ram,0x015341cc) */
/* WARNING: Removing unreachable block (ram,0x015341e4) */
/* WARNING: Removing unreachable block (ram,0x015341e8) */
/* WARNING: Removing unreachable block (ram,0x015341f0) */
/* WARNING: Removing unreachable block (ram,0x01534398) */
/* WARNING: Removing unreachable block (ram,0x01534200) */
/* WARNING: Removing unreachable block (ram,0x015343b0) */
/* WARNING: Removing unreachable block (ram,0x01534214) */
/* WARNING: Removing unreachable block (ram,0x01534228) */
/* WARNING: Removing unreachable block (ram,0x015343c8) */
/* WARNING: Removing unreachable block (ram,0x01533ed4) */
/* WARNING: Removing unreachable block (ram,0x015336f8) */
/* WARNING: Removing unreachable block (ram,0x0153367c) */
/* WARNING: Removing unreachable block (ram,0x01534420) */
/* WARNING: Removing unreachable block (ram,0x01534454) */
/* WARNING: Removing unreachable block (ram,0x0153443c) */
/* WARNING: Removing unreachable block (ram,0x0153446c) */
/* WARNING: Removing unreachable block (ram,0x01534490) */
/* WARNING: Removing unreachable block (ram,0x015344bc) */
/* WARNING: Removing unreachable block (ram,0x015344c8) */
/* WARNING: Removing unreachable block (ram,0x015344e4) */
/* WARNING: Removing unreachable block (ram,0x015344f8) */
/* WARNING: Removing unreachable block (ram,0x0153452c) */
/* WARNING: Removing unreachable block (ram,0x015345ac) */
/* WARNING: Removing unreachable block (ram,0x015345b4) */
/* WARNING: Removing unreachable block (ram,0x015344ec) */
/* WARNING: Removing unreachable block (ram,0x015345bc) */
/* WARNING: Removing unreachable block (ram,0x015345c4) */
/* WARNING: Removing unreachable block (ram,0x015345e4) */
/* WARNING: Removing unreachable block (ram,0x015345e8) */
/* WARNING: Removing unreachable block (ram,0x01534498) */
/* WARNING: Removing unreachable block (ram,0x01534474) */
/* WARNING: Removing unreachable block (ram,0x01534444) */
/* WARNING: Removing unreachable block (ram,0x015345fc) */
/* WARNING: Removing unreachable block (ram,0x01534608) */
/* WARNING: Removing unreachable block (ram,0x01534634) */
/* WARNING: Removing unreachable block (ram,0x01532f9c) */
/* WARNING: Removing unreachable block (ram,0x01534640) */
/* WARNING: Removing unreachable block (ram,0x01534658) */
/* WARNING: Removing unreachable block (ram,0x0153466c) */
/* WARNING: Removing unreachable block (ram,0x01534678) */
/* WARNING: Removing unreachable block (ram,0x0153464c) */
/* WARNING: Removing unreachable block (ram,0x0153467c) */
/* WARNING: Removing unreachable block (ram,0x01534654) */
/* WARNING: Removing unreachable block (ram,0x01534690) */
/* WARNING: Removing unreachable block (ram,0x01532fac) */
/* WARNING: Removing unreachable block (ram,0x015335d8) */
/* WARNING: Removing unreachable block (ram,0x015335dc) */
/* WARNING: Removing unreachable block (ram,0x0153335c) */
/* WARNING: Removing unreachable block (ram,0x01533360) */
/* WARNING: Removing unreachable block (ram,0x0153338c) */
/* WARNING: Removing unreachable block (ram,0x015333d4) */
/* WARNING: Removing unreachable block (ram,0x015333f4) */
/* WARNING: Removing unreachable block (ram,0x01533408) */
/* WARNING: Removing unreachable block (ram,0x01533414) */
/* WARNING: Removing unreachable block (ram,0x015333e8) */
/* WARNING: Removing unreachable block (ram,0x01533418) */
/* WARNING: Removing unreachable block (ram,0x015333f0) */
/* WARNING: Removing unreachable block (ram,0x01533434) */
/* WARNING: Removing unreachable block (ram,0x0153344c) */
/* WARNING: Removing unreachable block (ram,0x01533464) */
/* WARNING: Removing unreachable block (ram,0x01533398) */
/* WARNING: Removing unreachable block (ram,0x015333d0) */
/* WARNING: Removing unreachable block (ram,0x01533328) */
/* WARNING: Removing unreachable block (ram,0x0153332c) */
/* WARNING: Removing unreachable block (ram,0x015332f8) */
/* WARNING: Removing unreachable block (ram,0x015332fc) */
/* WARNING: Removing unreachable block (ram,0x01533298) */
/* WARNING: Removing unreachable block (ram,0x015332a0) */
/* WARNING: Removing unreachable block (ram,0x01533220) */
/* WARNING: Removing unreachable block (ram,0x01533224) */
/* WARNING: Removing unreachable block (ram,0x015346a4) */
/* WARNING: Removing unreachable block (ram,0x01533260) */
/* WARNING: Removing unreachable block (ram,0x01534fa8) */
/* WARNING: Removing unreachable block (ram,0x01535974) */
/* WARNING: Removing unreachable block (ram,0x01534fac) */
/* WARNING: Removing unreachable block (ram,0x01534fc4) */
/* WARNING: Removing unreachable block (ram,0x01534fd0) */
/* WARNING: Removing unreachable block (ram,0x01534fd8) */
/* WARNING: Removing unreachable block (ram,0x01534fe4) */
/* WARNING: Removing unreachable block (ram,0x01535008) */
/* WARNING: Removing unreachable block (ram,0x0153501c) */
/* WARNING: Removing unreachable block (ram,0x0153502c) */
/* WARNING: Removing unreachable block (ram,0x01534ff8) */
/* WARNING: Removing unreachable block (ram,0x01535030) */
/* WARNING: Removing unreachable block (ram,0x01535004) */
/* WARNING: Removing unreachable block (ram,0x0153504c) */
/* WARNING: Removing unreachable block (ram,0x01535064) */
/* WARNING: Removing unreachable block (ram,0x0153506c) */
/* WARNING: Removing unreachable block (ram,0x01535074) */
/* WARNING: Removing unreachable block (ram,0x01535080) */
/* WARNING: Removing unreachable block (ram,0x015350b0) */
/* WARNING: Removing unreachable block (ram,0x01535084) */
/* WARNING: Removing unreachable block (ram,0x015350d4) */
/* WARNING: Removing unreachable block (ram,0x0153508c) */
/* WARNING: Removing unreachable block (ram,0x015350f8) */
/* WARNING: Removing unreachable block (ram,0x01535094) */
/* WARNING: Removing unreachable block (ram,0x0153512c) */
/* WARNING: Removing unreachable block (ram,0x01535138) */
/* WARNING: Removing unreachable block (ram,0x015350ac) */
/* WARNING: Removing unreachable block (ram,0x01535150) */
/* WARNING: Removing unreachable block (ram,0x01535168) */
/* WARNING: Removing unreachable block (ram,0x0153517c) */
/* WARNING: Removing unreachable block (ram,0x01535188) */
/* WARNING: Removing unreachable block (ram,0x0153515c) */
/* WARNING: Removing unreachable block (ram,0x0153518c) */
/* WARNING: Removing unreachable block (ram,0x01535164) */
/* WARNING: Removing unreachable block (ram,0x015351a4) */
/* WARNING: Removing unreachable block (ram,0x015351b8) */
/* WARNING: Removing unreachable block (ram,0x015351c0) */
/* WARNING: Removing unreachable block (ram,0x01535874) */
/* WARNING: Removing unreachable block (ram,0x015351cc) */
/* WARNING: Removing unreachable block (ram,0x015351d8) */
/* WARNING: Removing unreachable block (ram,0x0153590c) */
/* WARNING: Removing unreachable block (ram,0x01535910) */
/* WARNING: Removing unreachable block (ram,0x0153591c) */
/* WARNING: Removing unreachable block (ram,0x01535928) */
/* WARNING: Removing unreachable block (ram,0x01535940) */
/* WARNING: Removing unreachable block (ram,0x01535954) */
/* WARNING: Removing unreachable block (ram,0x015351f8) */
/* WARNING: Removing unreachable block (ram,0x01535224) */
/* WARNING: Removing unreachable block (ram,0x01535958) */
/* WARNING: Removing unreachable block (ram,0x01535230) */
/* WARNING: Removing unreachable block (ram,0x0153523c) */
/* WARNING: Removing unreachable block (ram,0x01535254) */
/* WARNING: Removing unreachable block (ram,0x01535258) */
/* WARNING: Removing unreachable block (ram,0x0153527c) */
/* WARNING: Removing unreachable block (ram,0x015352a8) */
/* WARNING: Removing unreachable block (ram,0x015352ac) */
/* WARNING: Removing unreachable block (ram,0x015352c4) */
/* WARNING: Removing unreachable block (ram,0x015352d0) */
/* WARNING: Removing unreachable block (ram,0x015352d4) */
/* WARNING: Removing unreachable block (ram,0x015352dc) */
/* WARNING: Removing unreachable block (ram,0x01535288) */
/* WARNING: Removing unreachable block (ram,0x015352e0) */
/* WARNING: Removing unreachable block (ram,0x01535290) */
/* WARNING: Removing unreachable block (ram,0x015352ec) */
/* WARNING: Removing unreachable block (ram,0x015352a0) */
/* WARNING: Removing unreachable block (ram,0x015352f4) */
/* WARNING: Removing unreachable block (ram,0x01535318) */
/* WARNING: Removing unreachable block (ram,0x0153533c) */
/* WARNING: Removing unreachable block (ram,0x015353a8) */
/* WARNING: Removing unreachable block (ram,0x01535350) */
/* WARNING: Removing unreachable block (ram,0x015353bc) */
/* WARNING: Removing unreachable block (ram,0x01535368) */
/* WARNING: Removing unreachable block (ram,0x015353d4) */
/* WARNING: Removing unreachable block (ram,0x0153537c) */
/* WARNING: Removing unreachable block (ram,0x015353e8) */
/* WARNING: Removing unreachable block (ram,0x01535394) */
/* WARNING: Removing unreachable block (ram,0x015353fc) */
/* WARNING: Removing unreachable block (ram,0x015354f4) */
/* WARNING: Removing unreachable block (ram,0x01535410) */
/* WARNING: Removing unreachable block (ram,0x01535504) */
/* WARNING: Removing unreachable block (ram,0x01535424) */
/* WARNING: Removing unreachable block (ram,0x0153551c) */
/* WARNING: Removing unreachable block (ram,0x01535438) */
/* WARNING: Removing unreachable block (ram,0x01535530) */
/* WARNING: Removing unreachable block (ram,0x01535450) */
/* WARNING: Removing unreachable block (ram,0x0153554c) */
/* WARNING: Removing unreachable block (ram,0x01535468) */
/* WARNING: Removing unreachable block (ram,0x0153555c) */
/* WARNING: Removing unreachable block (ram,0x0153547c) */
/* WARNING: Removing unreachable block (ram,0x01535570) */
/* WARNING: Removing unreachable block (ram,0x0153548c) */
/* WARNING: Removing unreachable block (ram,0x01535580) */
/* WARNING: Removing unreachable block (ram,0x015354a0) */
/* WARNING: Removing unreachable block (ram,0x0153559c) */
/* WARNING: Removing unreachable block (ram,0x015354b8) */
/* WARNING: Removing unreachable block (ram,0x015355ac) */
/* WARNING: Removing unreachable block (ram,0x015354cc) */
/* WARNING: Removing unreachable block (ram,0x015355c0) */
/* WARNING: Removing unreachable block (ram,0x015354dc) */
/* WARNING: Removing unreachable block (ram,0x015355d0) */
/* WARNING: Removing unreachable block (ram,0x015354f0) */
/* WARNING: Removing unreachable block (ram,0x015353a4) */
/* WARNING: Removing unreachable block (ram,0x015355d4) */
/* WARNING: Removing unreachable block (ram,0x015355d8) */
/* WARNING: Removing unreachable block (ram,0x01535644) */
/* WARNING: Removing unreachable block (ram,0x015355ec) */
/* WARNING: Removing unreachable block (ram,0x01535658) */
/* WARNING: Removing unreachable block (ram,0x01535604) */
/* WARNING: Removing unreachable block (ram,0x01535670) */
/* WARNING: Removing unreachable block (ram,0x01535618) */
/* WARNING: Removing unreachable block (ram,0x01535684) */
/* WARNING: Removing unreachable block (ram,0x01535630) */
/* WARNING: Removing unreachable block (ram,0x01535640) */
/* WARNING: Removing unreachable block (ram,0x01535698) */
/* WARNING: Removing unreachable block (ram,0x01535790) */
/* WARNING: Removing unreachable block (ram,0x015356ac) */
/* WARNING: Removing unreachable block (ram,0x015357a0) */
/* WARNING: Removing unreachable block (ram,0x015356c0) */
/* WARNING: Removing unreachable block (ram,0x015357b8) */
/* WARNING: Removing unreachable block (ram,0x015356d4) */
/* WARNING: Removing unreachable block (ram,0x015357cc) */
/* WARNING: Removing unreachable block (ram,0x015356ec) */
/* WARNING: Removing unreachable block (ram,0x015357e8) */
/* WARNING: Removing unreachable block (ram,0x01535704) */
/* WARNING: Removing unreachable block (ram,0x015357f8) */
/* WARNING: Removing unreachable block (ram,0x01535718) */
/* WARNING: Removing unreachable block (ram,0x0153580c) */
/* WARNING: Removing unreachable block (ram,0x01535728) */
/* WARNING: Removing unreachable block (ram,0x0153581c) */
/* WARNING: Removing unreachable block (ram,0x0153573c) */
/* WARNING: Removing unreachable block (ram,0x01535838) */
/* WARNING: Removing unreachable block (ram,0x01535754) */
/* WARNING: Removing unreachable block (ram,0x01535848) */
/* WARNING: Removing unreachable block (ram,0x01535768) */
/* WARNING: Removing unreachable block (ram,0x0153585c) */
/* WARNING: Removing unreachable block (ram,0x01535778) */
/* WARNING: Removing unreachable block (ram,0x0153578c) */
/* WARNING: Removing unreachable block (ram,0x0153586c) */
/* WARNING: Removing unreachable block (ram,0x01535304) */
/* WARNING: Removing unreachable block (ram,0x01535264) */
/* WARNING: Removing unreachable block (ram,0x01535270) */
/* WARNING: Removing unreachable block (ram,0x01535274) */
/* WARNING: Removing unreachable block (ram,0x0153520c) */
/* WARNING: Removing unreachable block (ram,0x0153587c) */
/* WARNING: Removing unreachable block (ram,0x01535894) */
/* WARNING: Removing unreachable block (ram,0x015358b8) */
/* WARNING: Removing unreachable block (ram,0x015358d4) */
/* WARNING: Removing unreachable block (ram,0x015358e8) */
/* WARNING: Removing unreachable block (ram,0x015358f4) */
/* WARNING: Removing unreachable block (ram,0x015358c8) */
/* WARNING: Removing unreachable block (ram,0x01534c88) */
/* WARNING: Removing unreachable block (ram,0x015358d0) */
/* WARNING: Removing unreachable block (ram,0x015358f8) */
/* WARNING: Removing unreachable block (ram,0x015358a0) */
/* WARNING: Type propagation algorithm not settling */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

segment_command *
__ZN5Proxy14SaveSturdyJPEGERNSt3__114basic_ofstreamIcNS0_11char_traitsIcEEEER12CImageBufferjbb
          (long *param_1,long param_2,segment_command *param_3,segment_command *param_4,
          char *param_5,segment_command *param_6,segment_command *param_7)

{
  byte bVar1;
  ushort uVar2;
  ushort uVar3;
  ushort uVar4;
  int iVar5;
  int iVar6;
  undefined1 auVar8 [16];
  undefined1 auVar9 [16];
  undefined1 auVar10 [16];
  char *pcVar11;
  char *pcVar12;
  undefined1 *puVar13;
  undefined1 *puVar14;
  undefined1 *puVar15;
  undefined1 *puVar16;
  undefined1 *puVar17;
  undefined1 *puVar18;
  undefined1 *puVar19;
  undefined1 *puVar20;
  qword *pqVar21;
  undefined1 *puVar22;
  undefined1 *puVar23;
  undefined1 *puVar24;
  undefined1 *puVar25;
  dword dVar26;
  undefined1 uVar27;
  undefined1 uVar28;
  undefined1 uVar29;
  undefined1 uVar30;
  code *pcVar31;
  segment_command **ppsVar32;
  double *pdVar33;
  segment_command **ppsVar34;
  undefined1 *puVar35;
  bool bVar37;
  dword *pdVar38;
  int iVar42;
  uint uVar43;
  undefined4 uVar44;
  segment_command *psVar45;
  segment_command *psVar46;
  ushort *puVar47;
  undefined2 *puVar48;
  undefined8 *puVar49;
  segment_command *psVar50;
  long *plVar51;
  long *plVar52;
  long *plVar53;
  undefined4 uVar55;
  long *plVar54;
  segment_command *psVar56;
  segment_command *psVar57;
  dword *pdVar58;
  segment_command *psVar59;
  ushort *puVar60;
  segment_command *psVar61;
  segment_command *psVar62;
  char *pcVar63;
  segment_command *psVar64;
  uint uVar65;
  uint uVar66;
  float *pfVar67;
  int iVar68;
  ulong uVar69;
  undefined4 uVar70;
  uint *puVar71;
  long *plVar72;
  float *pfVar73;
  int *piVar74;
  uint uVar75;
  float *pfVar76;
  long lVar77;
  segment_command *psVar78;
  uint uVar79;
  dword *pdVar80;
  long lVar81;
  undefined4 *puVar82;
  uint uVar83;
  long lVar84;
  long lVar85;
  byte *pbVar86;
  uint uVar87;
  long lVar88;
  long lVar89;
  long lVar90;
  undefined2 *puVar91;
  segment_command *unaff_x19;
  segment_command *psVar92;
  ulong uVar93;
  int iVar94;
  segment_command *unaff_x21;
  segment_command *psVar95;
  long *plVar96;
  segment_command *unaff_x22;
  segment_command *unaff_x23;
  ulong uVar97;
  ulong uVar98;
  ulong unaff_x24;
  long lVar99;
  segment_command *unaff_x25;
  long lVar100;
  float *unaff_x26;
  segment_command *unaff_x27;
  segment_command *psVar101;
  uint *puVar102;
  long *plVar103;
  ulong unaff_x28;
  char *pcVar104;
  undefined4 *puVar105;
  undefined1 *puVar106;
  undefined1 **ppuVar107;
  float *pfVar108;
  undefined8 uVar109;
  uint uVar110;
  int iVar114;
  int iVar115;
  undefined1 auVar111 [16];
  undefined1 auVar112 [16];
  undefined1 auVar113 [16];
  float fVar116;
  float fVar117;
  float fVar118;
  float fVar121;
  float fVar122;
  undefined1 auVar119 [16];
  undefined1 auVar120 [16];
  float fVar123;
  float fVar124;
  float fVar125;
  float fVar129;
  float fVar130;
  undefined1 auVar126 [16];
  undefined1 auVar127 [16];
  undefined1 auVar128 [16];
  float fVar131;
  int iVar136;
  undefined1 auVar132 [16];
  undefined1 auVar133 [16];
  undefined1 auVar134 [16];
  undefined1 auVar135 [16];
  float fVar137;
  float fVar138;
  int iVar142;
  float fVar143;
  int iVar144;
  float fVar145;
  int iVar146;
  undefined1 auVar139 [16];
  undefined1 auVar140 [16];
  undefined1 auVar141 [16];
  float fVar147;
  float fVar148;
  float fVar154;
  float fVar155;
  undefined1 auVar149 [16];
  undefined1 auVar150 [16];
  undefined1 auVar151 [16];
  undefined1 auVar152 [16];
  undefined1 auVar153 [16];
  float fVar156;
  float fVar157;
  float fVar162;
  float fVar163;
  undefined1 auVar158 [16];
  undefined1 auVar159 [16];
  undefined1 auVar160 [16];
  undefined1 auVar161 [16];
  float fVar164;
  undefined1 auVar165 [16];
  undefined1 auVar166 [16];
  undefined1 auVar167 [16];
  undefined1 auVar168 [16];
  float fVar169;
  ulong unaff_d8;
  ulong unaff_d9;
  ulong unaff_d10;
  undefined8 unaff_d11;
  float fVar170;
  undefined1 auVar171 [16];
  undefined1 auVar172 [16];
  undefined1 auVar173 [16];
  undefined1 auVar174 [16];
  segment_command *psStack_1050;
  double dStack_1048;
  dword *pdStack_1038;
  long lStack_1030;
  uint uStack_1028;
  uint uStack_1024;
  undefined8 uStack_1020;
  uint uStack_1014;
  uint uStack_1010;
  int iStack_100c;
  int *piStack_1008;
  uint uStack_ffc;
  char *pcStack_ff8;
  char *pcStack_ff0;
  segment_command *psStack_fe8;
  segment_command *psStack_fe0;
  long lStack_fd8;
  long lStack_fd0;
  uint uStack_fc4;
  segment_command *psStack_fc0;
  segment_command *psStack_fb8;
  char *pcStack_fb0;
  segment_command *psStack_fa8;
  ulong uStack_fa0;
  undefined8 uStack_f98;
  segment_command *psStack_f88;
  long lStack_f80;
  undefined8 uStack_f78;
  segment_command *psStack_f70;
  undefined8 uStack_f68;
  long lStack_f58;
  char *pcStack_f48;
  char cStack_f40;
  undefined1 auStack_d38 [80];
  segment_command sStack_ce8;
  int iStack_c94;
  int iStack_c90;
  int iStack_c8c;
  ushort auStack_c88 [2];
  uint uStack_c84;
  uint uStack_c80;
  int iStack_c7c;
  uint auStack_c78 [8];
  int aiStack_c58 [12];
  int aiStack_c28 [10];
  uint auStack_c00 [10];
  ushort uStack_bd8;
  ushort uStack_bd6;
  ushort uStack_bd4;
  long alStack_bd0 [3];
  segment_command *psStack_bb8;
  float *pfStack_bb0;
  segment_command *psStack_ba8;
  ulong uStack_ba0;
  segment_command *psStack_b98;
  segment_command *psStack_b90;
  segment_command *psStack_b88;
  segment_command *psStack_b80;
  segment_command *psStack_b78;
  undefined1 *puStack_b70;
  undefined8 uStack_b68;
  double dStack_b60;
  double dStack_b58;
  double dStack_b50;
  char *pcStack_b48;
  double dStack_b40;
  double dStack_b38;
  undefined8 uStack_b30;
  undefined8 uStack_b28;
  undefined8 uStack_b20;
  undefined8 uStack_b18;
  undefined8 uStack_b10;
  undefined8 uStack_b08;
  undefined8 uStack_b00;
  undefined8 uStack_af8;
  undefined8 uStack_af0;
  undefined8 uStack_ae8;
  long *plStack_ad8;
  int iStack_acc;
  undefined1 *puStack_ac8;
  undefined1 *puStack_ac0;
  segment_command *psStack_ab8;
  segment_command *psStack_ab0;
  char *pcStack_aa8;
  long lStack_aa0;
  uint uStack_a94;
  char *pcStack_a90;
  long lStack_a88;
  char *pcStack_a80;
  segment_command *psStack_a78;
  char *pcStack_a68;
  ulong uStack_a60;
  segment_command *psStack_a50;
  segment_command *psStack_a48;
  segment_command *psStack_a38;
  segment_command *psStack_a30;
  segment_command *psStack_a28;
  ulong uStack_a10;
  uint uStack_a04;
  long lStack_a00;
  float *pfStack_9f8;
  ulong uStack_9f0;
  undefined8 uStack_9e8;
  ulong uStack_9e0;
  undefined8 uStack_9d8;
  ulong uStack_9d0;
  undefined8 uStack_9c8;
  ulong uStack_9b8;
  ulong uStack_9b0;
  segment_command *psStack_9a8;
  segment_command sStack_9a0;
  undefined8 uStack_958;
  undefined8 uStack_950;
  undefined8 uStack_948;
  undefined8 uStack_940;
  undefined8 uStack_938;
  undefined8 uStack_930;
  undefined8 uStack_928;
  undefined8 uStack_920;
  undefined8 uStack_918;
  undefined8 uStack_910;
  undefined8 uStack_908;
  undefined8 uStack_900;
  undefined8 uStack_8f8;
  undefined8 uStack_8f0;
  undefined8 uStack_8e8;
  undefined8 uStack_8e0;
  undefined8 uStack_8d8;
  undefined8 uStack_8d0;
  undefined8 uStack_8c8;
  undefined8 uStack_8c0;
  undefined8 uStack_8b8;
  undefined8 uStack_8b0;
  undefined8 uStack_8a8;
  undefined8 uStack_8a0;
  undefined8 uStack_898;
  undefined8 uStack_890;
  undefined8 uStack_888;
  undefined8 uStack_880;
  undefined8 uStack_878;
  undefined8 uStack_870;
  undefined8 uStack_868;
  undefined8 uStack_860;
  undefined8 uStack_858;
  undefined8 uStack_850;
  undefined8 uStack_848;
  undefined8 uStack_840;
  undefined8 uStack_838;
  undefined8 uStack_830;
  undefined8 uStack_828;
  undefined8 uStack_820;
  undefined8 uStack_818;
  undefined8 uStack_810;
  undefined8 uStack_808;
  undefined8 uStack_800;
  undefined8 uStack_7f8;
  undefined8 uStack_7f0;
  undefined8 uStack_7e8;
  undefined8 uStack_7e0;
  undefined8 uStack_7d8;
  undefined8 uStack_7d0;
  undefined8 uStack_7c8;
  undefined8 uStack_7c0;
  undefined8 uStack_7b8;
  undefined8 uStack_7b0;
  undefined1 auStack_7a8 [8];
  float *pfStack_7a0;
  long alStack_798 [62];
  segment_command sStack_5a8;
  undefined8 uStack_560;
  undefined8 uStack_558;
  undefined8 uStack_550;
  undefined8 uStack_548;
  undefined8 uStack_540;
  undefined8 uStack_538;
  undefined8 uStack_530;
  undefined8 uStack_528;
  undefined8 uStack_520;
  undefined8 uStack_518;
  undefined8 uStack_510;
  undefined8 uStack_508;
  undefined8 uStack_500;
  undefined8 uStack_4f8;
  undefined8 uStack_4f0;
  undefined8 uStack_4e8;
  undefined8 uStack_4e0;
  undefined8 uStack_4d8;
  undefined8 uStack_4d0;
  undefined8 uStack_4c8;
  undefined8 uStack_4c0;
  undefined8 uStack_4b8;
  undefined8 uStack_4b0;
  undefined8 uStack_4a8;
  segment_command sStack_4a0;
  undefined8 uStack_458;
  undefined8 uStack_450;
  undefined8 uStack_448;
  undefined8 uStack_440;
  undefined8 uStack_438;
  undefined8 uStack_430;
  undefined8 uStack_428;
  undefined8 uStack_420;
  undefined8 uStack_418;
  undefined8 uStack_410;
  undefined8 uStack_408;
  undefined8 uStack_400;
  undefined8 uStack_3f8;
  undefined8 uStack_3f0;
  undefined8 uStack_3e8;
  undefined8 uStack_3e0;
  undefined8 uStack_3d8;
  undefined8 uStack_3d0;
  undefined8 uStack_3c8;
  undefined8 uStack_3c0;
  undefined8 uStack_3b8;
  undefined8 uStack_3b0;
  undefined8 uStack_3a8;
  undefined8 uStack_3a0;
  undefined8 uStack_398;
  undefined8 uStack_390;
  undefined8 uStack_388;
  undefined8 uStack_380;
  undefined8 uStack_378;
  undefined8 uStack_370;
  undefined8 uStack_368;
  undefined8 uStack_360;
  undefined8 uStack_358;
  undefined8 uStack_350;
  undefined8 uStack_348;
  undefined8 uStack_340;
  undefined8 uStack_338;
  undefined8 uStack_330;
  undefined8 uStack_328;
  undefined8 uStack_320;
  undefined8 uStack_318;
  undefined8 uStack_310;
  undefined8 uStack_308;
  undefined8 uStack_300;
  undefined8 uStack_2f8;
  undefined8 uStack_2f0;
  undefined8 uStack_2e8;
  undefined8 uStack_2e0;
  undefined8 uStack_2d8;
  undefined8 uStack_2d0;
  undefined8 uStack_2c8;
  undefined8 uStack_2c0;
  undefined8 uStack_2b8;
  undefined8 uStack_2b0;
  undefined8 uStack_2a8;
  undefined1 auStack_2a0 [8];
  undefined8 uStack_298;
  char acStack_290 [8];
  qword qStack_288;
  qword qStack_280;
  qword qStack_278;
  qword qStack_270;
  undefined8 uStack_268;
  undefined8 uStack_260;
  undefined8 uStack_258;
  undefined8 uStack_250;
  undefined8 uStack_248;
  undefined8 uStack_240;
  undefined8 uStack_238;
  undefined8 uStack_230;
  undefined8 uStack_228;
  undefined8 uStack_220;
  undefined8 uStack_218;
  undefined8 uStack_210;
  undefined8 uStack_208;
  undefined8 uStack_200;
  undefined8 uStack_1f8;
  undefined8 uStack_1f0;
  undefined8 uStack_1e8;
  undefined8 uStack_1e0;
  undefined8 uStack_1d8;
  undefined8 uStack_1d0;
  undefined8 uStack_1c8;
  undefined8 uStack_1c0;
  undefined8 uStack_1b8;
  undefined8 uStack_1b0;
  undefined8 uStack_1a8;
  undefined8 uStack_1a0;
  undefined8 uStack_198;
  undefined8 uStack_190;
  undefined8 uStack_188;
  undefined8 uStack_180;
  undefined8 uStack_178;
  undefined8 uStack_170;
  undefined8 uStack_168;
  undefined8 uStack_160;
  undefined8 uStack_158;
  undefined8 uStack_150;
  undefined8 uStack_148;
  undefined8 uStack_140;
  undefined8 uStack_138;
  undefined8 uStack_130;
  undefined8 uStack_128;
  undefined8 uStack_120;
  undefined8 uStack_118;
  undefined8 uStack_110;
  undefined8 uStack_108;
  undefined8 uStack_100;
  undefined8 uStack_f8;
  undefined8 uStack_f0;
  undefined8 uStack_e8;
  undefined8 uStack_e0;
  undefined8 uStack_d8;
  undefined8 uStack_d0;
  undefined8 uStack_c8;
  undefined8 uStack_c0;
  undefined8 uStack_b8;
  undefined8 uStack_b0;
  char acStack_a8 [24];
  qword qStack_90;
  undefined1 auVar7 [12];
  segment_command **ppsVar36;
  qword *pqVar39;
  qword *pqVar40;
  qword *pqVar41;

  puVar106 = &stack0xfffffffffffffff0;
  pdVar33 = &dStack_b60;
  qStack_90 = *(qword *)PTR____stack_chk_guard_01d15188;
  if (*(int *)(param_2 + 0x28) == 3) {
    iStack_acc = (int)param_5;
    uVar110 = *(uint *)(param_2 + 0x20);
    unaff_x19 = (segment_command *)(ulong)uVar110;
    uVar65 = *(uint *)(param_2 + 0x24);
    unaff_x26 = (float *)(ulong)uVar65;
    if (*(long *)(param_2 + 0x40) == 0) {
      unaff_x22 = (segment_command *)0x0;
      uVar93 = *(ulong *)(param_2 + 0x38);
    }
    else {
      uVar93 = *(ulong *)(param_2 + 0x38);
      unaff_x22 = (segment_command *)
                  (*(long *)(param_2 + 0x40) +
                  uVar93 * (long)*(int *)(param_2 + 0x1c) + (long)*(int *)(param_2 + 0x18) * 6);
    }
    uVar43 = (uVar110 * 3 + 0x30) * (uVar65 + 0x10) + 0x100000;
    psStack_ab8 = (segment_command *)(ulong)uVar43;
    pfVar108 = (float *)0x1531e0c;
    psVar59 = param_3;
    psVar62 = param_4;
    plStack_ad8 = param_1;
    psVar45 = (segment_command *)_malloc((long)(int)uVar43);
    if (psVar45 == (segment_command *)0x0) {
      psStack_b80 = (segment_command *)0x0;
      unaff_x21 = param_4;
      unaff_x23 = param_3;
    }
    else {
      uStack_a04 = (uint)param_3;
      *(undefined8 *)((long)&psVar45[2].fileoff + 4) = 0;
      *(undefined8 *)((long)&psVar45[2].vmsize + 4) = 0;
      lStack_a00 = (long)(int)uVar110;
      psVar45[2].vmsize = 0;
      psVar45[2].vmaddr = 0;
      unaff_x24 = uVar93 >> 1;
      psVar45[2].segname[8] = '\0';
      psVar45[2].segname[9] = '\0';
      psVar45[2].segname[10] = '\0';
      psVar45[2].segname[0xb] = '\0';
      psVar45[2].segname[0xc] = '\0';
      psVar45[2].segname[0xd] = '\0';
      psVar45[2].segname[0xe] = '\0';
      psVar45[2].segname[0xf] = '\0';
      psVar45[2].segname[0] = '\0';
      psVar45[2].segname[1] = '\0';
      psVar45[2].segname[2] = '\0';
      psVar45[2].segname[3] = '\0';
      psVar45[2].segname[4] = '\0';
      psVar45[2].segname[5] = '\0';
      psVar45[2].segname[6] = '\0';
      psVar45[2].segname[7] = '\0';
      psVar45[2].cmd = 0;
      psVar45[2].cmdsize = 0;
      psVar45[1].nsects = 0;
      psVar45[1].flags = 0;
      psVar45[1].maxprot = 0;
      psVar45[1].initprot = 0;
      psVar45[1].filesize = 0;
      psVar45[1].fileoff = 0;
      psVar45[1].vmsize = 0;
      psVar45[1].vmaddr = 0;
      psVar45[1].segname[8] = '\0';
      psVar45[1].segname[9] = '\0';
      psVar45[1].segname[10] = '\0';
      psVar45[1].segname[0xb] = '\0';
      psVar45[1].segname[0xc] = '\0';
      psVar45[1].segname[0xd] = '\0';
      psVar45[1].segname[0xe] = '\0';
      psVar45[1].segname[0xf] = '\0';
      psVar45[1].segname[0] = '\0';
      psVar45[1].segname[1] = '\0';
      psVar45[1].segname[2] = '\0';
      psVar45[1].segname[3] = '\0';
      psVar45[1].segname[4] = '\0';
      psVar45[1].segname[5] = '\0';
      psVar45[1].segname[6] = '\0';
      psVar45[1].segname[7] = '\0';
      psVar45[1].cmd = 0;
      psVar45[1].cmdsize = 0;
      psVar45->nsects = 0;
      psVar45->flags = 0;
      psVar45->maxprot = 0;
      psVar45->initprot = 0;
      psVar45->filesize = 0;
      psVar45->fileoff = 0;
      psVar45->vmsize = 0;
      psVar45->vmaddr = 0;
      psVar45->cmd = (dword)(float)_UNK_01a9c0f8;
      uVar27 = UNK_01a9c104;
      uVar28 = UNK_01a9c105;
      uVar29 = UNK_01a9c106;
      uVar30 = UNK_01a9c107;
      psVar45->cmdsize = _UNK_01a9c100;
      psVar45->segname[0] = uVar27;
      psVar45->segname[1] = uVar28;
      psVar45->segname[2] = uVar29;
      psVar45->segname[3] = uVar30;
      psVar45->segname[4] = '\x03';
      psVar45->segname[5] = '\0';
      psVar45->segname[6] = '\0';
      psVar45->segname[7] = '\0';
      *(uint *)(psVar45->segname + 8) = uVar110;
      *(uint *)(psVar45->segname + 0xc) = uVar65;
      psStack_a50 = psVar45;
      pfStack_9f8 = unaff_x26;
      if ((int)param_4 == 0) {
LAB_01532554:
        *(undefined4 *)((long)&psStack_a50[2].fileoff + 4) = 0x200020;
        *(undefined2 *)&psStack_a50[2].filesize = 0x20;
        auVar112 = ZEXT816(0x3f800000);
        uStack_9f0 = 0x3f800000;
        uStack_9e8 = 0;
        auVar171 = ZEXT816(0x3f800000);
      }
      else {
        uStack_a10 = unaff_x24;
        uStack_298._0_1_ = '\0';
        uStack_298._1_1_ = '\0';
        uStack_298._2_1_ = '\0';
        uStack_298._3_1_ = '\0';
        uStack_298._4_1_ = '\0';
        uStack_298._5_1_ = '\0';
        uStack_298._6_1_ = '\0';
        uStack_298._7_1_ = '\0';
        auStack_2a0._0_4_ = 0;
        auStack_2a0._4_4_ = 0;
        qStack_288 = 0;
        acStack_290[0] = '\0';
        acStack_290[1] = '\0';
        acStack_290[2] = '\0';
        acStack_290[3] = '\0';
        acStack_290[4] = '\0';
        acStack_290[5] = '\0';
        acStack_290[6] = '\0';
        acStack_290[7] = '\0';
        qStack_278 = 0;
        qStack_280 = 0;
        uStack_268._0_4_ = 0;
        uStack_268._4_4_ = 0;
        qStack_270 = 0;
        uStack_258 = 0;
        uStack_260._0_4_ = 0;
        uStack_260._4_4_ = 0;
        uStack_248 = 0;
        uStack_250 = 0;
        uStack_238 = 0;
        uStack_240 = 0;
        uStack_228 = 0;
        uStack_230 = 0;
        uStack_218 = 0;
        uStack_220 = 0;
        uStack_208 = 0;
        uStack_210 = 0;
        uStack_1f8 = 0;
        uStack_200 = 0;
        uStack_1e8 = 0;
        uStack_1f0 = 0;
        uStack_1d8 = 0;
        uStack_1e0 = 0;
        uStack_1c8 = 0;
        uStack_1d0 = 0;
        uStack_1b8 = 0;
        uStack_1c0 = 0;
        uStack_1a8 = 0;
        uStack_1b0 = 0;
        uStack_198 = 0;
        uStack_1a0 = 0;
        uStack_188 = 0;
        uStack_190 = 0;
        uStack_178 = 0;
        uStack_180 = 0;
        uStack_168 = 0;
        uStack_170 = 0;
        uStack_158 = 0;
        uStack_160 = 0;
        uStack_148 = 0;
        uStack_150 = 0;
        uStack_138 = 0;
        uStack_140 = 0;
        uStack_128 = 0;
        uStack_130 = 0;
        uStack_118 = 0;
        uStack_120 = 0;
        uStack_108 = 0;
        uStack_110 = 0;
        uStack_f8 = 0;
        uStack_100 = 0;
        uStack_e8 = 0;
        uStack_f0 = 0;
        uStack_d8 = 0;
        uStack_e0 = 0;
        uStack_c8 = 0;
        uStack_d0 = 0;
        uStack_b8 = 0;
        uStack_c0 = 0;
        acStack_a8._0_8_ = 0;
        uStack_b0 = 0;
        uStack_2a8 = 0;
        uStack_2b0 = 0;
        uStack_2b8 = 0;
        uStack_2c0 = 0;
        uStack_2c8 = 0;
        uStack_2d0 = 0;
        uStack_2d8 = 0;
        uStack_2e0 = 0;
        uStack_2e8 = 0;
        uStack_2f0 = 0;
        uStack_2f8 = 0;
        uStack_300 = 0;
        uStack_308 = 0;
        uStack_310 = 0;
        uStack_318 = 0;
        uStack_320 = 0;
        uStack_328 = 0;
        uStack_330 = 0;
        uStack_338 = 0;
        uStack_340 = 0;
        uStack_348 = 0;
        uStack_350 = 0;
        uStack_358 = 0;
        uStack_360 = 0;
        uStack_368 = 0;
        uStack_370 = 0;
        uStack_378 = 0;
        uStack_380 = 0;
        uStack_388 = 0;
        uStack_390 = 0;
        uStack_398 = 0;
        uStack_3a0 = 0;
        alStack_798[0] = 0;
        pfStack_7a0 = (float *)0x0;
        alStack_798[2] = 0;
        alStack_798[1] = 0;
        alStack_798[4] = 0;
        alStack_798[3] = 0;
        alStack_798[6]._0_4_ = 0;
        alStack_798[6]._4_4_ = 0;
        alStack_798[5]._0_4_ = 0;
        alStack_798[5]._4_4_ = 0;
        alStack_798[8] = 0;
        alStack_798[7] = 0;
        alStack_798[10] = 0;
        alStack_798[9] = 0;
        alStack_798[0xc] = 0;
        alStack_798[0xb] = 0;
        alStack_798[0xe] = 0;
        alStack_798[0xd] = 0;
        alStack_798[0x10] = 0;
        alStack_798[0xf] = 0;
        alStack_798[0x12] = 0;
        alStack_798[0x11] = 0;
        alStack_798[0x14] = 0;
        alStack_798[0x13] = 0;
        alStack_798[0x16] = 0;
        alStack_798[0x15] = 0;
        alStack_798[0x18] = 0;
        alStack_798[0x17] = 0;
        alStack_798[0x1a] = 0;
        alStack_798[0x19] = 0;
        alStack_798[0x1c] = 0;
        alStack_798[0x1b] = 0;
        alStack_798[0x1e] = 0;
        alStack_798[0x1d] = 0;
        alStack_798[0x20] = 0;
        alStack_798[0x1f] = 0;
        alStack_798[0x22] = 0;
        alStack_798[0x21] = 0;
        alStack_798[0x24] = 0;
        alStack_798[0x23] = 0;
        alStack_798[0x26] = 0;
        alStack_798[0x25] = 0;
        alStack_798[0x28] = 0;
        alStack_798[0x27] = 0;
        alStack_798[0x2a] = 0;
        alStack_798[0x29] = 0;
        alStack_798[0x2c] = 0;
        alStack_798[0x2b] = 0;
        alStack_798[0x2e] = 0;
        alStack_798[0x2d] = 0;
        alStack_798[0x30] = 0;
        alStack_798[0x2f] = 0;
        alStack_798[0x32] = 0;
        alStack_798[0x31] = 0;
        alStack_798[0x34] = 0;
        alStack_798[0x33] = 0;
        alStack_798[0x36] = 0;
        alStack_798[0x35] = 0;
        alStack_798[0x38] = 0;
        alStack_798[0x37] = 0;
        alStack_798[0x3a] = 0;
        alStack_798[0x39] = 0;
        alStack_798[0x3c] = 0;
        alStack_798[0x3b] = 0;
        sStack_5a8.cmd = 0;
        sStack_5a8.cmdsize = 0;
        alStack_798[0x3d] = 0;
        uStack_3a8 = 0;
        uStack_3b0 = 0;
        uStack_3b8 = 0;
        uStack_3c0 = 0;
        uStack_3c8 = 0;
        uStack_3d0 = 0;
        uStack_3d8 = 0;
        uStack_3e0 = 0;
        uStack_3e8 = 0;
        uStack_3f0 = 0;
        uStack_3f8 = 0;
        uStack_400 = 0;
        uStack_408 = 0;
        uStack_410 = 0;
        uStack_418 = 0;
        uStack_420 = 0;
        uStack_428 = 0;
        uStack_430 = 0;
        uStack_438 = 0;
        uStack_440 = 0;
        uStack_448 = 0;
        uStack_450 = 0;
        uStack_458 = 0;
        sStack_4a0.nsects = 0;
        sStack_4a0.flags = 0;
        sStack_4a0.maxprot = 0;
        sStack_4a0.initprot = 0;
        sStack_4a0.filesize = 0;
        sStack_4a0.fileoff = 0;
        sStack_4a0.vmsize = 0;
        sStack_4a0.vmaddr = 0;
        sStack_4a0.segname[8] = '\0';
        sStack_4a0.segname[9] = '\0';
        sStack_4a0.segname[10] = '\0';
        sStack_4a0.segname[0xb] = '\0';
        sStack_4a0.segname[0xc] = '\0';
        sStack_4a0.segname[0xd] = '\0';
        sStack_4a0.segname[0xe] = '\0';
        sStack_4a0.segname[0xf] = '\0';
        sStack_4a0.segname[0] = '\0';
        sStack_4a0.segname[1] = '\0';
        sStack_4a0.segname[2] = '\0';
        sStack_4a0.segname[3] = '\0';
        sStack_4a0.segname[4] = '\0';
        sStack_4a0.segname[5] = '\0';
        sStack_4a0.segname[6] = '\0';
        sStack_4a0.segname[7] = '\0';
        sStack_4a0.cmd = 0;
        sStack_4a0.cmdsize = 0;
        sStack_9a0.segname[0] = '\0';
        sStack_9a0.segname[1] = '\0';
        sStack_9a0.segname[2] = '\0';
        sStack_9a0.segname[3] = '\0';
        sStack_9a0.segname[4] = '\0';
        sStack_9a0.segname[5] = '\0';
        sStack_9a0.segname[6] = '\0';
        sStack_9a0.segname[7] = '\0';
        sStack_9a0.cmd = 0;
        sStack_9a0.cmdsize = 0;
        sStack_9a0.vmaddr = 0;
        sStack_9a0.segname[8] = '\0';
        sStack_9a0.segname[9] = '\0';
        sStack_9a0.segname[10] = '\0';
        sStack_9a0.segname[0xb] = '\0';
        sStack_9a0.segname[0xc] = '\0';
        sStack_9a0.segname[0xd] = '\0';
        sStack_9a0.segname[0xe] = '\0';
        sStack_9a0.segname[0xf] = '\0';
        sStack_9a0.fileoff = 0;
        sStack_9a0.vmsize = 0;
        sStack_9a0.maxprot = 0;
        sStack_9a0.initprot = 0;
        sStack_9a0.filesize = 0;
        uStack_958 = 0;
        sStack_9a0.nsects = 0;
        sStack_9a0.flags = 0;
        uStack_948 = 0;
        uStack_950 = 0;
        uStack_938 = 0;
        uStack_940 = 0;
        uStack_928 = 0;
        uStack_930 = 0;
        uStack_918 = 0;
        uStack_920 = 0;
        uStack_908 = 0;
        uStack_910 = 0;
        uStack_8f8 = 0;
        uStack_900 = 0;
        uStack_8e8 = 0;
        uStack_8f0 = 0;
        uStack_8d8 = 0;
        uStack_8e0 = 0;
        uStack_8c8 = 0;
        uStack_8d0 = 0;
        uStack_8b8 = 0;
        uStack_8c0 = 0;
        uStack_8a8 = 0;
        uStack_8b0 = 0;
        uStack_898 = 0;
        uStack_8a0 = 0;
        uStack_888 = 0;
        uStack_890 = 0;
        uStack_878 = 0;
        uStack_880 = 0;
        uStack_868 = 0;
        uStack_870 = 0;
        uStack_858 = 0;
        uStack_860 = 0;
        uStack_848 = 0;
        uStack_850 = 0;
        uStack_838 = 0;
        uStack_840 = 0;
        uStack_828 = 0;
        uStack_830 = 0;
        uStack_818 = 0;
        uStack_820 = 0;
        uStack_808 = 0;
        uStack_810 = 0;
        uStack_7f8 = 0;
        uStack_800 = 0;
        uStack_7e8 = 0;
        uStack_7f0 = 0;
        uStack_7d8 = 0;
        uStack_7e0 = 0;
        uStack_7c8 = 0;
        uStack_7d0 = 0;
        uStack_7b8 = 0;
        uStack_7c0 = 0;
        auStack_7a8._0_4_ = 0;
        auStack_7a8._4_4_ = 0;
        uStack_7b0 = 0;
        uStack_4a8 = 0;
        uStack_4b0 = 0;
        uStack_4b8 = 0;
        uStack_4c0 = 0;
        uStack_4c8 = 0;
        uStack_4d0 = 0;
        uStack_4d8 = 0;
        uStack_4e0 = 0;
        uStack_4e8 = 0;
        uStack_4f0 = 0;
        uStack_4f8 = 0;
        uStack_500 = 0;
        uStack_508 = 0;
        uStack_510 = 0;
        uStack_518 = 0;
        uStack_520 = 0;
        uStack_528 = 0;
        uStack_530 = 0;
        uStack_538 = 0;
        uStack_540 = 0;
        uStack_548 = 0;
        uStack_550 = 0;
        uStack_558 = 0;
        uStack_560 = 0;
        sStack_5a8.nsects = 0;
        sStack_5a8.flags = 0;
        sStack_5a8.maxprot = 0;
        sStack_5a8.initprot = 0;
        sStack_5a8.filesize = 0;
        sStack_5a8.fileoff = 0;
        uVar79 = 0x20;
        sStack_5a8.vmsize = 0;
        sStack_5a8.vmaddr = 0;
        sStack_5a8.segname[8] = '\0';
        sStack_5a8.segname[9] = '\0';
        sStack_5a8.segname[10] = '\0';
        sStack_5a8.segname[0xb] = '\0';
        sStack_5a8.segname[0xc] = '\0';
        sStack_5a8.segname[0xd] = '\0';
        sStack_5a8.segname[0xe] = '\0';
        sStack_5a8.segname[0xf] = '\0';
        sStack_5a8.segname[0] = '\0';
        sStack_5a8.segname[1] = '\0';
        sStack_5a8.segname[2] = '\0';
        sStack_5a8.segname[3] = '\0';
        sStack_5a8.segname[4] = '\0';
        sStack_5a8.segname[5] = '\0';
        sStack_5a8.segname[6] = '\0';
        sStack_5a8.segname[7] = '\0';
        uVar66 = 0x20;
        uVar43 = 0x20;
        if ((0 < (int)uVar65) && (0 < (int)uVar110)) {
          pfVar76 = (float *)0x0;
          pdVar58 = &unaff_x22->cmdsize;
          uVar79 = 0x20;
          psVar59 = unaff_x19;
          pdVar80 = pdVar58;
          do {
            do {
              uVar3 = (ushort)((segment_command *)(pdVar58 + -1))->cmd;
              uVar4 = *(ushort *)((long)pdVar58 + -2);
              uVar2 = (ushort)*pdVar58;
              if (uVar43 <= uVar3) {
                uVar43 = (uint)uVar3;
              }
              if (uVar66 <= uVar4) {
                uVar66 = (uint)uVar4;
              }
              if (uVar79 <= uVar2) {
                uVar79 = (uint)uVar2;
              }
              iVar68 = (int)SQRT((float)(uint)uVar3);
              iVar94 = (int)SQRT((float)(uint)uVar4);
              iVar42 = iVar68 + 3;
              if (-1 < iVar68) {
                iVar42 = iVar68;
              }
              uVar87 = iVar42 >> 2;
              iVar42 = iVar94 + 3;
              if (-1 < iVar94) {
                iVar42 = iVar94;
              }
              iVar68 = (int)SQRT((float)(uint)uVar2);
              uVar83 = iVar42 >> 2;
              iVar42 = iVar68 + 3;
              if (-1 < iVar68) {
                iVar42 = iVar68;
              }
              uVar75 = iVar42 >> 2;
              uVar97 = -(ulong)(uVar87 >> 0x1f) & 0xfffffffc00000000 | (ulong)uVar87 << 2;
              uVar69 = -(ulong)(uVar87 >> 0x1f) & 0xfffffff800000000 | (ulong)uVar87 << 3;
              lVar100 = *(long *)(auStack_2a0 + uVar69);
              *(int *)((long)&uStack_3a0 + uVar97) = *(int *)((long)&uStack_3a0 + uVar97) + 1;
              uVar98 = -(ulong)(uVar83 >> 0x1f) & 0xfffffffc00000000 | (ulong)uVar83 << 2;
              iVar42 = *(int *)(sStack_4a0.segname + (uVar98 - 8));
              *(ulong *)(auStack_2a0 + uVar69) = lVar100 + (ulong)uVar3;
              uVar97 = -(ulong)(uVar83 >> 0x1f) & 0xfffffff800000000 | (ulong)uVar83 << 3;
              lVar100 = *(long *)(auStack_7a8 + uVar97 + 8);
              *(int *)(sStack_4a0.segname + (uVar98 - 8)) = iVar42 + 1;
              uVar69 = -(ulong)(uVar75 >> 0x1f) & 0xfffffffc00000000 | (ulong)uVar75 << 2;
              iVar42 = *(int *)(sStack_5a8.segname + uVar69);
              *(ulong *)(auStack_7a8 + uVar97 + 8) = lVar100 + (ulong)uVar4;
              uVar97 = -(ulong)(uVar75 >> 0x1f) & 0xfffffff800000000 | (ulong)uVar75 << 3;
              lVar100 = *(long *)(sStack_9a0.segname + (uVar97 - 8));
              *(int *)(sStack_5a8.segname + uVar69) = iVar42 + 1;
              *(ulong *)(sStack_9a0.segname + (uVar97 - 8)) = lVar100 + (ulong)uVar2;
              psVar59 = (segment_command *)((long)&psVar59[-1].flags + 3);
              pdVar58 = (dword *)((long)pdVar58 + 6);
            } while (psVar59 != (segment_command *)0x0);
            pfVar76 = (float *)((long)pfVar76 + 1);
            pdVar58 = (dword *)((long)pdVar80 +
                               (-(uVar93 >> 0x20 & 1) & 0xfffffffe00000000 |
                               (unaff_x24 & 0xffffffff) << 1));
            psVar59 = unaff_x19;
            pdVar80 = pdVar58;
          } while (pfVar76 != unaff_x26);
        }
        lVar90 = 0;
        lVar89 = 0;
        lVar88 = 0;
        pfVar76 = (float *)0x0;
        lVar85 = 0;
        lVar84 = 0;
        psVar95 = (segment_command *)0x0;
        lVar81 = 0;
        lVar77 = 0;
        uVar93 = 0;
        iVar42 = uVar65 * uVar110;
        lVar100 = (long)(SQRT((float)iVar42) * 0.5) + 1;
        psVar59 = (segment_command *)(lVar100 * 2);
        psVar62 = (segment_command *)((ulong)((long)iVar42 * 0x51eb851f) >> 0x3f);
        psVar46 = (segment_command *)(long)(iVar42 / 100);
        if ((long)psVar59 - (long)psVar46 == 0 || (long)psVar59 < (long)psVar46) {
          psVar59 = psVar46;
        }
        param_5 = auStack_7a8;
        param_6 = &sStack_5a8;
        param_7 = (segment_command *)acStack_a8;
        pfVar73 = unaff_x26;
        do {
          lVar99 = lVar90 * 4;
          pfVar76 = (float *)((long)pfVar76 + (ulong)*(uint *)((long)&uStack_2a8 + lVar99 + 4));
          if (lVar100 < (long)pfVar76 && lVar88 != 0) {
            psVar95 = (segment_command *)
                      (psVar95->segname + ((ulong)*(uint *)((long)&uStack_3a8 + lVar99 + 4) - 8));
            if ((long)psVar95 <= lVar100 || lVar84 == 0) goto LAB_015322f8;
LAB_015322a0:
            uVar93 = uVar93 + *(uint *)((long)&uStack_4a8 + lVar99 + 4);
            if ((long)uVar93 <= lVar100 || lVar77 == 0) goto LAB_01532318;
LAB_015322b4:
            if ((long)pfVar76 <= (long)psVar59 || lVar89 <= lVar88) goto LAB_01532330;
LAB_015322c0:
            if ((long)psVar95 <= (long)psVar59 || lVar85 <= lVar84) goto LAB_01532348;
LAB_015322cc:
            if ((long)uVar93 <= (long)psVar59) goto LAB_0153225c;
LAB_0153235c:
            if (lVar81 <= lVar77) goto LAB_0153225c;
          }
          else {
            lVar88 = *(long *)(param_7->segname + lVar90 * 8 + -8) + lVar88;
            psVar95 = (segment_command *)
                      (psVar95->segname + ((ulong)*(uint *)((long)&uStack_3a8 + lVar99 + 4) - 8));
            pfVar73 = pfVar76;
            if (lVar100 < (long)psVar95 && lVar84 != 0) goto LAB_015322a0;
LAB_015322f8:
            lVar84 = *(long *)(param_6->segname + lVar90 * 8 + -8) + lVar84;
            psStack_9a8 = psVar95;
            uVar93 = uVar93 + *(uint *)((long)&uStack_4a8 + lVar99 + 4);
            if (lVar100 < (long)uVar93 && lVar77 != 0) goto LAB_015322b4;
LAB_01532318:
            lVar77 = *(long *)(((segment_command *)param_5)->segname + lVar90 * 8 + -8) + lVar77;
            uStack_9b0 = uVar93;
            if ((long)psVar59 < (long)pfVar76 && lVar88 < lVar89) goto LAB_015322c0;
LAB_01532330:
            lVar89 = *(long *)(param_7->segname + lVar90 * 8 + -8) + lVar89;
            pfVar108 = pfVar76;
            if ((long)psVar59 < (long)psVar95 && lVar84 < lVar85) goto LAB_015322cc;
LAB_01532348:
            psVar62 = psVar95;
            lVar85 = *(long *)(param_6->segname + lVar90 * 8 + -8) + lVar85;
            psVar95 = psVar62;
            if ((long)psVar59 < (long)uVar93) goto LAB_0153235c;
LAB_0153225c:
            lVar81 = *(long *)(((segment_command *)param_5)->segname + lVar90 * 8 + -8) + lVar81;
            uStack_9b8 = uVar93;
          }
          psVar46 = psStack_9a8;
          uVar69 = uStack_9b0;
          lVar90 = lVar90 + -1;
        } while (lVar90 != -0x40);
        fVar169 = (float)(long)pfVar108;
        unaff_d8 = (ulong)(uint)fVar169;
        uVar83 = uVar66;
        uVar87 = uVar43;
        uVar75 = uVar79;
        if ((long)pfVar108 - (long)pfVar73 == 0 || (long)pfVar108 < (long)pfVar73) {
          unaff_d9 = (ulong)(uint)(float)(long)psVar62;
          lVar100 = (long)psVar62 - (long)psStack_9a8;
          if (lVar100 != 0 && (long)psStack_9a8 <= (long)psVar62) goto LAB_015326cc;
LAB_01532398:
          unaff_d10 = (ulong)(uint)(float)(long)uStack_9b8;
          lVar100 = uStack_9b8 - uStack_9b0;
          if (lVar100 != 0 && (long)uStack_9b0 <= (long)uStack_9b8) goto LAB_015323a8;
        }
        else {
          fVar116 = (float)lVar88 / (float)(long)pfVar73;
          uVar87 = (uint)(fVar116 + ((fVar116 - (float)lVar89 / fVar169) * (float)(long)pfVar73) /
                                    (float)((long)pfVar108 - (long)pfVar73) + 0.9);
          if ((int)uVar87 < 0x21 || (int)uVar43 <= (int)uVar87) {
            uVar87 = uVar43;
          }
          unaff_d9 = (ulong)(uint)(float)(long)psVar62;
          lVar100 = (long)psVar62 - (long)psStack_9a8;
          if (lVar100 == 0 || (long)psVar62 < (long)psStack_9a8) goto LAB_01532398;
LAB_015326cc:
          fVar116 = (float)lVar84 / (float)(long)psStack_9a8;
          uVar83 = (uint)(fVar116 + ((fVar116 - (float)lVar85 / (float)unaff_d9) *
                                    (float)(long)psStack_9a8) / (float)lVar100 + 0.9);
          if ((int)uVar83 < 0x21 || (int)uVar66 <= (int)uVar83) {
            uVar83 = uVar66;
          }
          unaff_d10 = (ulong)(uint)(float)(long)uStack_9b8;
          lVar100 = uStack_9b8 - uStack_9b0;
          if (lVar100 != 0 && (long)uStack_9b0 <= (long)uStack_9b8) {
LAB_015323a8:
            fVar116 = (float)lVar77 / (float)(long)uStack_9b0;
            uVar75 = (uint)(fVar116 + ((fVar116 - (float)lVar81 / (float)unaff_d10) *
                                      (float)(long)uStack_9b0) / (float)lVar100 + 0.9);
            if ((int)uVar75 < 0x21 || (int)uVar79 <= (int)uVar75) {
              uVar75 = uVar79;
            }
          }
        }
        *(short *)((long)&psVar45[2].fileoff + 4) = (short)(int)(2.09712e+06 / (float)(int)uVar87);
        *(short *)((long)&psVar45[2].fileoff + 6) = (short)(int)(2.09712e+06 / (float)(int)uVar83);
        *(short *)&psVar45[2].filesize = (short)(int)(2.09712e+06 / (float)(int)uVar75);
        fVar137 = (float)(uint)(int)(2.09712e+06 / (float)(int)uVar87) * 0.03125;
        auVar171._0_8_ = CONCAT44(0,fVar137);
        auVar171._8_8_ = 0;
        fVar170 = (float)(uint)(int)(2.09712e+06 / (float)(int)uVar83) * 0.03125;
        uStack_9f0 = (ulong)(uint)fVar170;
        uStack_9e8 = 0;
        fVar116 = (float)(uint)(int)(2.09712e+06 / (float)(int)uVar75) * 0.03125;
        auVar112._0_8_ = CONCAT44(0,fVar116);
        auVar112._8_8_ = 0;
        uVar43 = (uint)(4.0 <= fVar137);
        if (4.0 <= fVar170) {
          uVar43 = 1;
        }
        if (4.0 <= fVar116) {
          uVar43 = 1;
        }
        if (__DEBUG_PROXY_CREATE != 0) {
          pcStack_b48 = "yes";
          if (uVar43 == 0) {
            pcStack_b48 = "no";
          }
          dStack_b60 = (double)fVar137;
          dStack_b58 = (double)fVar170;
          dStack_b50 = (double)fVar116;
          uStack_9d8 = 0;
          uStack_9c8 = 0;
          uStack_9e8 = 0;
          psStack_9a8 = (segment_command *)CONCAT44(psStack_9a8._4_4_,uVar43);
          uStack_9e0 = auVar171._0_8_;
          uStack_9d0 = auVar112._0_8_;
          func_0x00574108("Proxy::SaveSturdyJPEG: global gains (%.2f, %.2f, %.2f); enabled: %s");
          dStack_b60 = (double)((fVar169 / (float)(long)pfVar76) * 100.0);
          dStack_b58 = (double)(((float)(long)pfVar73 / (float)(long)pfVar76) * 100.0);
          dStack_b50 = (double)(((float)unaff_d9 / (float)(long)psVar95) * 100.0);
          pcStack_b48 = (char *)(double)(((float)(long)psVar46 / (float)(long)psVar95) * 100.0);
          dStack_b40 = (double)(((float)unaff_d10 / (float)(long)uVar93) * 100.0);
          dStack_b38 = (double)(((float)(long)uVar69 / (float)(long)uVar93) * 100.0);
          func_0x00574108(
                         "Proxy::SaveSturdyJPEG: ratios r = (%.2f;%.2f); g = (%.2f;%.2f); b = (%.2f;%.2f)"
                         );
          auVar171._8_8_ = uStack_9d8;
          auVar171._0_8_ = uStack_9e0;
          auVar112._8_8_ = uStack_9c8;
          auVar112._0_8_ = uStack_9d0;
          uVar43 = (uint)psStack_9a8;
        }
        if ((uVar43 & 1) == 0) goto LAB_01532554;
      }
      pfVar108 = (float *)(long)(int)uVar65;
      puVar71 = (uint *)((long)&psStack_a50[1].vmsize + 4);
      unaff_x28 = 0xffffffff00000000;
      psVar45 = unaff_x19;
      uVar93 = 0;
      do {
        uStack_a60 = uVar93;
        uVar66 = (uint)psVar45;
        uVar79 = (uint)unaff_x26;
        uVar65 = uVar66;
        uVar43 = uVar79;
        if (0x20 < (int)uVar79) {
          uVar65 = uVar66 + 7 & 0xfffffff8;
          uVar43 = uVar79 + 7 & 0xfffffff8;
        }
        bVar37 = 0x7ff < (int)(uVar79 * uVar66);
        uVar87 = uVar66;
        uVar83 = uVar79;
        if (bVar37) {
          uVar87 = uVar65;
          uVar83 = uVar43;
        }
        uVar65 = uVar66;
        uVar43 = uVar79;
        if (0x20 < (int)uVar66) {
          uVar65 = uVar87;
          uVar43 = uVar83;
        }
        uVar87 = uVar66;
        uVar83 = uVar79;
        if ((long)(uStack_a60 - 1) < 8) {
          uVar87 = uVar65;
          uVar83 = uVar43;
        }
        *puVar71 = uVar87;
        puVar71[10] = uVar83;
        if ((int)uVar87 < 0) {
          uVar87 = uVar87 + 1;
        }
        psVar45 = (segment_command *)(ulong)(uint)((int)uVar87 >> 1);
        if ((int)uVar83 < 0) {
          uVar83 = uVar83 + 1;
        }
        unaff_x26 = (float *)(ulong)(uint)((int)uVar83 >> 1);
        uVar93 = uStack_a60 + 1;
        unaff_x28 = unaff_x28 + 0x100000000;
        puVar71 = puVar71 + 1;
      } while ((long)(uStack_a60 - 1) < 8 && (0x20 < (int)uVar66 && (bVar37 && 0x20 < (int)uVar79)))
      ;
      uStack_9b8 = uStack_a60 - 1;
      *(int *)&psStack_a50->vmaddr = (int)uStack_a60;
      uVar65 = *(uint *)((long)&psStack_a50[1].vmsize + 4);
      unaff_x27 = (segment_command *)(ulong)uVar65;
      uVar43 = psStack_a50[2].cmdsize;
      unaff_x21 = (segment_command *)(ulong)uVar43;
      psStack_9a8 = (segment_command *)(ulong)(uVar65 * 3);
      uVar66 = uVar65 * 3 * uVar43;
      unaff_x25 = (segment_command *)(long)(int)uVar66;
      uStack_9d8 = auVar171._8_8_;
      uStack_9e0 = auVar171._0_8_;
      uStack_9c8 = auVar112._8_8_;
      uStack_9d0 = auVar112._0_8_;
      if ((int)uStack_9b8 < -1) {
        iVar42 = 0;
      }
      else {
        if ((uint)uVar93 < 0x10) {
          uVar69 = 0;
          iVar42 = 0;
        }
        else {
          uVar69 = uVar93 & 0xfffffff0;
          puVar49 = (undefined8 *)((long)&psStack_a50[2].filesize + 4);
          iVar42 = 0;
          iVar68 = 0;
          iVar94 = 0;
          iVar114 = 0;
          uVar97 = uVar69;
          auVar171 = ZEXT816(0);
          auVar112 = ZEXT816(0);
          auVar120 = ZEXT816(0);
          do {
            iVar42 = iVar42 + *(int *)(puVar49 + -0xb) * (int)puVar49[-6] * 0xc;
            iVar68 = iVar68 + *(int *)((long)puVar49 + -0x54) * (int)((ulong)puVar49[-6] >> 0x20) *
                              0xc;
            iVar94 = iVar94 + *(int *)(puVar49 + -10) * (int)puVar49[-5] * 0xc;
            iVar114 = iVar114 + *(int *)((long)puVar49 + -0x4c) * (int)((ulong)puVar49[-5] >> 0x20)
                                * 0xc;
            auVar128._0_4_ = auVar171._0_4_ + *(int *)(puVar49 + -9) * (int)puVar49[-4] * 0xc;
            auVar128._4_4_ =
                 auVar171._4_4_ +
                 *(int *)((long)puVar49 + -0x44) * (int)((ulong)puVar49[-4] >> 0x20) * 0xc;
            auVar128._8_4_ = auVar171._8_4_ + *(int *)(puVar49 + -8) * (int)puVar49[-3] * 0xc;
            auVar128._12_4_ =
                 auVar171._12_4_ +
                 *(int *)((long)puVar49 + -0x3c) * (int)((ulong)puVar49[-3] >> 0x20) * 0xc;
            auVar135._0_4_ = auVar112._0_4_ + *(int *)(puVar49 + -7) * (int)puVar49[-2] * 0xc;
            auVar135._4_4_ =
                 auVar112._4_4_ +
                 ((segment_command *)((long)puVar49 + -0x34))->cmd *
                 (int)((ulong)puVar49[-2] >> 0x20) * 0xc;
            auVar135._8_4_ = auVar112._8_4_ + *(dword *)(puVar49 + -6) * (int)puVar49[-1] * 0xc;
            auVar135._12_4_ =
                 auVar112._12_4_ +
                 *(int *)((long)puVar49 + -0x2c) * (int)((ulong)puVar49[-1] >> 0x20) * 0xc;
            auVar153._0_4_ = auVar120._0_4_ + (int)puVar49[-5] * (int)*puVar49 * 0xc;
            auVar153._4_4_ =
                 auVar120._4_4_ +
                 (int)((ulong)puVar49[-5] >> 0x20) * (int)((ulong)*puVar49 >> 0x20) * 0xc;
            auVar153._8_4_ = auVar120._8_4_ + (int)puVar49[-4] * (int)puVar49[1] * 0xc;
            auVar153._12_4_ =
                 auVar120._12_4_ +
                 (int)((ulong)puVar49[-4] >> 0x20) * (int)((ulong)puVar49[1] >> 0x20) * 0xc;
            puVar49 = puVar49 + 8;
            uVar97 = uVar97 - 0x10;
            auVar171 = auVar128;
            auVar112 = auVar135;
            auVar120 = auVar153;
          } while (uVar97 != 0);
          iVar42 = auVar153._0_4_ + auVar135._0_4_ + auVar128._0_4_ + iVar42 +
                   auVar153._4_4_ + auVar135._4_4_ + auVar128._4_4_ + iVar68 +
                   auVar153._8_4_ + auVar135._8_4_ + auVar128._8_4_ + iVar94 +
                   auVar153._12_4_ + auVar135._12_4_ + auVar128._12_4_ + iVar114;
          if (uVar93 == uVar69) goto LAB_015327cc;
        }
        do {
          iVar42 = iVar42 + *(int *)(psStack_a50[1].segname + uVar69 * 4 + 0x1c) *
                            *(int *)(psStack_a50[2].segname + uVar69 * 4 + -4) * 0xc;
          uVar69 = uVar69 + 1;
        } while (uVar93 != uVar69);
      }
LAB_015327cc:
      psVar45 = (segment_command *)
                _malloc((long)(int)(uVar66 * 7 + ((int)(uVar43 + 7) >> 1) + iVar42));
      uVar69 = uStack_9b8;
      if (psVar45 == (segment_command *)0x0) {
        _free(psStack_a50);
        psStack_b80 = (segment_command *)0x0;
        unaff_x23 = (segment_command *)(ulong)uVar66;
        unaff_x26 = pfVar108;
      }
      else {
        uStack_a10 = (long)(int)(uVar66 * 4);
        psStack_ab0 = psVar45;
        pcStack_aa8 = unaff_x25->segname +
                      (long)((long)((segment_command *)
                                   (unaff_x25->segname +
                                   (long)(((segment_command *)
                                          (psVar45->segname + ((long)(int)(uVar66 * 4) - 8)))->
                                          segname + -0x10)))->segname + -0x10);
        pcStack_a68 = unaff_x25->segname +
                      (long)((long)((segment_command *)
                                   (unaff_x25->segname +
                                   (long)(((segment_command *)
                                          (psVar45->segname + ((long)(int)(uVar66 * 4) - 8)))->
                                          segname + -0x10)))->segname + -0x10) + (long)unaff_x25;
        iVar42 = (int)uStack_9b8;
        if (-2 < iVar42) {
          uVar97 = 0;
          do {
            alStack_798[uVar97 - 1] = (long)pcStack_a68;
            pcStack_a68 = pcStack_a68 +
                          *(int *)(psStack_a50[1].segname + uVar97 * 4 + 0x1c) *
                          *(int *)(psStack_a50[2].segname + uVar97 * 4 + -4) * 0xc;
            uVar97 = uVar97 + 1;
          } while (uVar93 != uVar97);
        }
        fVar116 = (float)uStack_9e0;
        fVar137 = (float)uStack_9f0;
        fVar169 = (float)uStack_9d0;
        if (0 < (int)uVar43) {
          psVar46 = (segment_command *)0x0;
          psVar78 = (segment_command *)((ulong)unaff_x19 & 0xfffffff8);
          uVar97 = -((ulong)psStack_9a8 >> 0x1f & 1) & 0xfffffffc00000000 |
                   ((ulong)psStack_9a8 & 0xffffffff) << 2;
          psVar95 = (segment_command *)(pfStack_7a0 + (long)(int)lStack_a00 * 3 + 2);
          pfVar76 = pfStack_7a0;
          do {
            iVar68 = (int)psVar46;
            if ((long)pfVar108 <= (long)psVar46) {
              iVar68 = ((int)pfStack_9f8 * 2 + -2) - (int)psVar46;
            }
            if (0 < (int)uVar110) {
              psVar59 = (segment_command *)(long)(iVar68 * (int)unaff_x24);
              if (uVar110 < 8) {
                psVar61 = (segment_command *)0x0;
              }
              else {
                psVar62 = (segment_command *)(unaff_x22->segname + (long)psVar59 * 2 + -8);
                psVar61 = psVar78;
                pfVar73 = pfVar76;
                do {
                  dVar26 = psVar62->cmd;
                  pcVar63 = (char *)((long)psVar62 + 2);
                  pdVar80 = (dword *)((long)psVar62 + 4);
                  pcVar104 = (char *)((long)psVar62 + 6);
                  pdVar38 = (dword *)((long)psVar62 + 8);
                  pcVar11 = (char *)((long)psVar62 + 10);
                  pdVar58 = (dword *)((long)psVar62 + 0xc);
                  pcVar12 = (char *)((long)psVar62 + 0xe);
                  pqVar21 = (qword *)((long)psVar62 + 0x10);
                  puVar13 = (undefined1 *)((long)psVar62 + 0x12);
                  puVar22 = (undefined1 *)((long)psVar62 + 0x14);
                  puVar14 = (undefined1 *)((long)psVar62 + 0x16);
                  pqVar39 = (qword *)((long)psVar62 + 0x18);
                  puVar15 = (undefined1 *)((long)psVar62 + 0x1a);
                  puVar23 = (undefined1 *)((long)psVar62 + 0x1c);
                  puVar16 = (undefined1 *)((long)psVar62 + 0x1e);
                  pqVar40 = (qword *)((long)psVar62 + 0x20);
                  puVar17 = (undefined1 *)((long)psVar62 + 0x22);
                  puVar24 = (undefined1 *)((long)psVar62 + 0x24);
                  puVar18 = (undefined1 *)((long)psVar62 + 0x26);
                  pqVar41 = (qword *)((long)psVar62 + 0x28);
                  puVar19 = (undefined1 *)((long)psVar62 + 0x2a);
                  puVar25 = (undefined1 *)((long)psVar62 + 0x2c);
                  puVar20 = (undefined1 *)((long)psVar62 + 0x2e);
                  psVar62 = (segment_command *)((long)psVar62 + 0x30);
                  auVar161._2_2_ = 0;
                  auVar161._0_2_ = (ushort)dVar26;
                  auVar161._4_2_ = *(undefined2 *)pcVar104;
                  auVar161._6_2_ = 0;
                  auVar161._8_2_ = (short)*pdVar58;
                  auVar161._10_2_ = 0;
                  auVar161._12_2_ = *(undefined2 *)puVar13;
                  auVar161._14_2_ = 0;
                  auVar112 = NEON_ucvtf(auVar161,4);
                  auVar168._2_2_ = 0;
                  auVar168._0_2_ = (ushort)*pqVar39;
                  auVar168._4_2_ = *(undefined2 *)puVar16;
                  auVar168._6_2_ = 0;
                  auVar168._8_2_ = *(undefined2 *)puVar24;
                  auVar168._10_2_ = 0;
                  auVar168._12_2_ = *(undefined2 *)puVar19;
                  auVar168._14_2_ = 0;
                  auVar128 = NEON_ucvtf(auVar168,4);
                  auVar149._2_2_ = 0;
                  auVar149._0_2_ = *(ushort *)pcVar63;
                  auVar149._4_2_ = (short)*pdVar38;
                  auVar149._6_2_ = 0;
                  auVar149._8_2_ = *(undefined2 *)pcVar12;
                  auVar149._10_2_ = 0;
                  auVar149._12_2_ = *(undefined2 *)puVar22;
                  auVar149._14_2_ = 0;
                  auVar135 = NEON_ucvtf(auVar149,4);
                  auVar158._2_2_ = 0;
                  auVar158._0_2_ = *(ushort *)puVar15;
                  auVar158._4_2_ = (short)*pqVar40;
                  auVar158._6_2_ = 0;
                  auVar158._8_2_ = *(undefined2 *)puVar18;
                  auVar158._10_2_ = 0;
                  auVar158._12_2_ = *(undefined2 *)puVar25;
                  auVar158._14_2_ = 0;
                  auVar153 = NEON_ucvtf(auVar158,4);
                  auVar165._2_2_ = 0;
                  auVar165._0_2_ = (ushort)*pdVar80;
                  auVar165._4_2_ = *(undefined2 *)pcVar11;
                  auVar165._6_2_ = 0;
                  auVar165._8_2_ = (short)*pqVar21;
                  auVar165._10_2_ = 0;
                  auVar165._12_2_ = *(undefined2 *)puVar14;
                  auVar165._14_2_ = 0;
                  auVar161 = NEON_ucvtf(auVar165,4);
                  auVar120._2_2_ = 0;
                  auVar120._0_2_ = *(ushort *)puVar23;
                  auVar120._4_2_ = *(undefined2 *)puVar17;
                  auVar120._6_2_ = 0;
                  auVar120._8_2_ = (short)*pqVar41;
                  auVar120._10_2_ = 0;
                  auVar120._12_2_ = *(undefined2 *)puVar20;
                  auVar120._14_2_ = 0;
                  auVar171 = NEON_ucvtf(auVar120,4);
                  param_6 = (segment_command *)(pfVar73 + 0x18);
                  *pfVar73 = auVar112._0_4_ * fVar116;
                  pfVar73[1] = auVar135._0_4_ * fVar137;
                  pfVar73[2] = auVar161._0_4_ * fVar169;
                  pfVar73[3] = auVar112._4_4_ * fVar116;
                  pfVar73[4] = auVar135._4_4_ * fVar137;
                  pfVar73[5] = auVar161._4_4_ * fVar169;
                  pfVar73[6] = auVar112._8_4_ * fVar116;
                  pfVar73[7] = auVar135._8_4_ * fVar137;
                  pfVar73[8] = auVar161._8_4_ * fVar169;
                  pfVar73[9] = auVar112._12_4_ * fVar116;
                  pfVar73[10] = auVar135._12_4_ * fVar137;
                  pfVar73[0xb] = auVar161._12_4_ * fVar169;
                  pfVar73[0xc] = auVar128._0_4_ * fVar116;
                  pfVar73[0xd] = auVar153._0_4_ * fVar137;
                  pfVar73[0xe] = auVar171._0_4_ * fVar169;
                  pfVar73[0xf] = auVar128._4_4_ * fVar116;
                  pfVar73[0x10] = auVar153._4_4_ * fVar137;
                  pfVar73[0x11] = auVar171._4_4_ * fVar169;
                  pfVar73[0x12] = auVar128._8_4_ * fVar116;
                  pfVar73[0x13] = auVar153._8_4_ * fVar137;
                  pfVar73[0x14] = auVar171._8_4_ * fVar169;
                  pfVar73[0x15] = auVar128._12_4_ * fVar116;
                  pfVar73[0x16] = auVar153._12_4_ * fVar137;
                  pfVar73[0x17] = auVar171._12_4_ * fVar169;
                  psVar61 = (segment_command *)&psVar61[-1].nsects;
                  pfVar73 = (float *)param_6;
                } while (psVar61 != (segment_command *)0x0);
                param_5 = (char *)psVar78;
                psVar61 = psVar78;
                if (psVar78 == unaff_x19) goto LAB_015329b8;
              }
              lVar100 = (long)unaff_x19 - (long)psVar61;
              psVar59 = (segment_command *)
                        (unaff_x22->segname + (long)psVar59 * 2 + (long)psVar61 * 6 + -4);
              param_5 = (char *)(pfVar76 + (long)psVar61 * 3);
              do {
                fVar170 = (float)NEON_ucvtf((uint)(ushort)psVar59[-1].flags);
                fVar117 = (float)NEON_ucvtf((uint)*(ushort *)((long)&psVar59[-1].flags + 2));
                fVar124 = (float)NEON_ucvtf((uint)(ushort)psVar59->cmd);
                ((segment_command *)param_5)->cmd = (dword)(fVar116 * fVar170);
                ((segment_command *)param_5)->cmdsize = (dword)(fVar137 * fVar117);
                *(float *)((segment_command *)param_5)->segname = fVar169 * fVar124;
                psVar59 = (segment_command *)((long)&psVar59->cmdsize + 2);
                param_5 = ((segment_command *)param_5)->segname + 4;
                lVar100 = lVar100 + -1;
                psVar62 = (segment_command *)0x0;
              } while (lVar100 != 0);
            }
LAB_015329b8:
            if ((int)uVar110 < (int)uVar65) {
              iVar68 = uVar110 * 3 + -6 + iVar68 * (int)unaff_x24;
              psVar62 = psVar95;
              lVar100 = (int)uVar65 - lStack_a00;
              do {
                fVar170 = (float)NEON_ucvtf((uint)*(ushort *)
                                                   (unaff_x22->segname + (long)iVar68 * 2 + -8));
                fVar117 = (float)NEON_ucvtf((uint)*(ushort *)
                                                   (unaff_x22->segname + (long)(iVar68 + 1) * 2 + -8
                                                   ));
                param_5 = (char *)(ulong)(iVar68 + 2U);
                fVar124 = (float)NEON_ucvtf((uint)*(ushort *)
                                                   (unaff_x22->segname +
                                                   (long)(int)(iVar68 + 2U) * 2 + -8));
                psVar62[-1].nsects = (dword)(fVar116 * fVar170);
                psVar62[-1].flags = (dword)(fVar137 * fVar117);
                psVar59 = (segment_command *)((long)psVar62->segname + 4);
                psVar62->cmd = (dword)(fVar169 * fVar124);
                iVar68 = iVar68 + -3;
                lVar100 = lVar100 + -1;
                psVar62 = psVar59;
              } while (lVar100 != 0);
              psVar62 = (segment_command *)0x0;
            }
            psVar46 = (segment_command *)((long)&psVar46->cmd + 1);
            pfVar76 = (float *)((long)pfVar76 + uVar97);
            psVar95 = (segment_command *)((long)psVar95->segname + (uVar97 - 8));
          } while (psVar46 != unaff_x21);
        }
        psStack_a38 = (segment_command *)
                      (unaff_x25->segname +
                      (long)(((segment_command *)(psVar45->segname + ((long)(int)(uVar66 * 4) - 8)))
                             ->segname + -0x10));
        psStack_a30 = (segment_command *)(psVar45->segname + ((long)(int)(uVar66 * 4) - 8));
        if (-1 < iVar42) {
          uVar97 = 0;
          pfVar76 = pfStack_7a0;
          psVar45 = unaff_x21;
          psVar95 = unaff_x27;
          do {
            uStack_9b0 = uVar97 + 1;
            pfVar73 = (float *)alStack_798[uVar97];
            uVar110 = *(uint *)(psStack_a50[1].segname + uVar97 * 4 + 0x20);
            unaff_x27 = (segment_command *)(ulong)uVar110;
            psStack_9a8 = unaff_x27;
            uVar65 = *(uint *)(psStack_a50[2].segname + uVar97 * 4);
            unaff_x21 = (segment_command *)(ulong)uVar65;
            if ((0 < (int)uVar65) && (0 < (int)uVar110)) {
              iVar68 = 0;
              uVar43 = 0;
              iVar115 = (int)psVar45;
              iVar136 = (int)psVar95;
              lVar81 = (long)iVar136;
              lVar100 = (long)unaff_x27 * 2;
              uVar66 = iVar136 * 2 - 2;
              psVar59 = (segment_command *)(ulong)uVar66;
              psVar62 = (segment_command *)(ulong)(iVar136 * 2 - 1);
              param_5 = (char *)((long)&MACH_HEADER.magic + 1);
              param_6 = (segment_command *)((long)&MACH_HEADER.magic + 2);
              iVar94 = iVar136 * 3;
              iVar114 = uVar110 * 3;
              do {
                lVar88 = 0;
                uVar110 = uVar43 * 2;
                if (iVar115 <= (int)uVar110) {
                  uVar110 = iVar115 * 2 + ~uVar110;
                }
                iVar142 = uVar110 - 1;
                if ((int)uVar110 < 1) {
                  iVar142 = -uVar110;
                }
                iVar144 = (iVar115 * 2 + -2) - uVar110;
                if ((int)(uVar110 + 1) < iVar115) {
                  iVar144 = uVar110 + 1;
                }
                iVar146 = uVar110 * iVar94;
                iVar142 = iVar142 * iVar94;
                pfVar108 = pfVar76 + iVar144 * iVar94;
                psVar45 = psVar62;
                iVar144 = iVar68;
                fVar170 = pfVar76[(long)iVar146 + 3] * 0.5 +
                          (pfVar76[(long)iVar142 + 3] + pfVar108[3]) * 0.25;
                do {
                  iVar6 = (int)lVar88;
                  if (lVar81 <= lVar88) {
                    iVar6 = (int)psVar45;
                  }
                  iVar5 = uVar66 - iVar6;
                  if (iVar6 + 1 < iVar136) {
                    iVar5 = iVar6 + 1;
                  }
                  uVar98 = -(ulong)((uint)(iVar6 * 3) >> 0x1f) & 0xfffffffc00000000 |
                           (ulong)(uint)(iVar6 * 3) << 2;
                  uVar97 = -(ulong)((uint)(iVar5 * 3) >> 0x1f) & 0xfffffffc00000000 |
                           (ulong)(uint)(iVar5 * 3) << 2;
                  fVar117 = *(float *)((long)pfVar76 + uVar97 + (long)iVar146 * 4) * 0.5 +
                            (*(float *)((long)pfVar76 + uVar97 + (long)iVar142 * 4) +
                            *(float *)((long)pfVar108 + uVar97)) * 0.25;
                  pfVar73[iVar144] =
                       (*(float *)((long)pfVar76 + uVar98 + (long)iVar146 * 4) * 0.5 +
                       (*(float *)((long)pfVar76 + uVar98 + (long)iVar142 * 4) +
                       *(float *)((long)pfVar108 + uVar98)) * 0.25) * 0.5 +
                       (fVar170 + fVar117) * 0.25;
                  lVar88 = lVar88 + 2;
                  iVar144 = iVar144 + 3;
                  psVar45 = (segment_command *)(ulong)((int)psVar45 - 2);
                  fVar170 = fVar117;
                } while (lVar100 - lVar88 != 0);
                lVar88 = 0;
                psVar45 = psVar62;
                psVar95 = (segment_command *)param_5;
                fVar170 = pfVar76[(long)iVar146 + 4] * 0.5 +
                          (pfVar76[(long)iVar142 + 4] + pfVar108[4]) * 0.25;
                do {
                  iVar144 = (int)lVar88;
                  if (lVar81 <= lVar88) {
                    iVar144 = (int)psVar45;
                  }
                  iVar6 = uVar66 - iVar144;
                  uVar110 = iVar144 + 1 + iVar144 * 2;
                  uVar97 = -(ulong)(uVar110 >> 0x1f) & 0xfffffffc00000000 | (ulong)uVar110 << 2;
                  if (iVar144 + 1 < iVar136) {
                    iVar6 = iVar144 + 1;
                  }
                  uVar110 = iVar6 * 3 + 1;
                  uVar98 = -(ulong)(uVar110 >> 0x1f) & 0xfffffffc00000000 | (ulong)uVar110 << 2;
                  fVar117 = *(float *)((long)pfVar76 + uVar98 + (long)iVar146 * 4) * 0.5 +
                            (*(float *)((long)pfVar76 + uVar98 + (long)iVar142 * 4) +
                            *(float *)((long)pfVar108 + uVar98)) * 0.25;
                  pfVar73[(int)psVar95] =
                       (*(float *)((long)pfVar76 + uVar97 + (long)iVar146 * 4) * 0.5 +
                       (*(float *)((long)pfVar76 + uVar97 + (long)iVar142 * 4) +
                       *(float *)((long)pfVar108 + uVar97)) * 0.25) * 0.5 +
                       (fVar170 + fVar117) * 0.25;
                  lVar88 = lVar88 + 2;
                  psVar95 = (segment_command *)(ulong)((int)psVar95 + 3);
                  psVar45 = (segment_command *)(ulong)((int)psVar45 - 2);
                  fVar170 = fVar117;
                } while (lVar100 - lVar88 != 0);
                lVar88 = 0;
                psVar45 = psVar62;
                psVar95 = param_6;
                fVar170 = pfVar76[(long)iVar146 + 5] * 0.5 +
                          (pfVar76[(long)iVar142 + 5] + pfVar108[5]) * 0.25;
                do {
                  iVar144 = (int)lVar88;
                  if (lVar81 <= lVar88) {
                    iVar144 = (int)psVar45;
                  }
                  iVar6 = uVar66 - iVar144;
                  uVar110 = iVar144 * 3 + 2;
                  uVar97 = -(ulong)(uVar110 >> 0x1f) & 0xfffffffc00000000 | (ulong)uVar110 << 2;
                  if (iVar144 + 1 < iVar136) {
                    iVar6 = iVar144 + 1;
                  }
                  uVar110 = iVar6 * 3 + 2;
                  uVar98 = -(ulong)(uVar110 >> 0x1f) & 0xfffffffc00000000 | (ulong)uVar110 << 2;
                  fVar117 = *(float *)((long)pfVar76 + uVar98 + (long)iVar146 * 4) * 0.5 +
                            (*(float *)((long)pfVar76 + uVar98 + (long)iVar142 * 4) +
                            *(float *)((long)pfVar108 + uVar98)) * 0.25;
                  pfVar73[(int)psVar95] =
                       (*(float *)((long)pfVar76 + uVar97 + (long)iVar146 * 4) * 0.5 +
                       (*(float *)((long)pfVar76 + uVar97 + (long)iVar142 * 4) +
                       *(float *)((long)pfVar108 + uVar97)) * 0.25) * 0.5 +
                       (fVar170 + fVar117) * 0.25;
                  lVar88 = lVar88 + 2;
                  psVar95 = (segment_command *)(ulong)((int)psVar95 + 3);
                  psVar45 = (segment_command *)(ulong)((int)psVar45 - 2);
                  fVar170 = fVar117;
                } while (lVar100 - lVar88 != 0);
                uVar43 = uVar43 + 1;
                iVar68 = iVar68 + iVar114;
                param_5 = (char *)(ulong)(uint)((int)param_5 + iVar114);
                param_6 = (segment_command *)(ulong)(uint)((int)param_6 + iVar114);
              } while (uVar43 != uVar65);
            }
            uVar97 = uStack_9b0;
            pfVar76 = pfVar73;
            psVar45 = unaff_x21;
            psVar95 = unaff_x27;
          } while (uStack_a60 != uStack_9b0);
        }
        if (-2 < iVar42) {
          fVar170 = (float)uStack_a04;
          unaff_d8 = (ulong)(uint)(fVar116 * fVar170);
          unaff_d9 = (ulong)(uint)(fVar137 * fVar170);
          unaff_d10 = (ulong)(uint)(fVar169 * fVar170);
          pdVar58 = &psStack_a50[2].cmdsize;
          puVar49 = (undefined8 *)(auStack_7a8 + 8);
          do {
            unaff_x21 = (segment_command *)(puVar49 + 1);
            psVar59 = (segment_command *)(ulong)*pdVar58;
            psVar62 = (segment_command *)((long)(int)pdVar58[-10] * 3);
            auStack_2a0._4_4_ = fVar137 * fVar170;
            auStack_2a0._0_4_ = fVar116 * fVar170;
            uStack_298._0_4_ = fVar169 * fVar170;
            param_5 = auStack_2a0;
            func_0x015308c0(*puVar49);
            uVar93 = uVar93 - 1;
            pdVar58 = pdVar58 + 1;
            puVar49 = (undefined8 *)unaff_x21;
          } while (uVar93 != 0);
        }
        unaff_x22 = psStack_a30;
        psVar45 = psStack_a38;
        uVar93 = uStack_a60;
        plVar51 = plStack_ad8;
        *(undefined2 *)&psStack_a50[2].maxprot = 0x4c;
        *(undefined4 *)((long)&psStack_a50[2].filesize + 4) = 0x4556454c;
        *(char *)((long)&psStack_a50[2].maxprot + 2) = (char)uStack_a60 + '0';
        *(undefined4 *)((long)&psStack_a50[2].maxprot + 3) = 0;
        *(undefined1 *)((long)&psStack_a50[2].initprot + 3) = 0;
        lVar81 = (long)unaff_x28 >> 0x20;
        lVar100 = (long)unaff_x28 >> 0x1e;
        unaff_x28 = 0xd0;
        pcVar63 = psStack_a50->segname + lVar100 + 0x14;
        pcVar63[0] = -0x30;
        pcVar63[1] = '\0';
        pcVar63[2] = '\0';
        pcVar63[3] = '\0';
        uVar110 = *(uint *)(psStack_a50[2].segname + lVar100 + -4);
        if ((int)uVar110 < 1) {
LAB_01532f18:
          *(int *)(psStack_a50->segname + lVar81 * 4 + 0x3c) = (int)unaff_x28 + -0xd0;
        }
        else {
          iVar68 = *(int *)(psStack_a50[1].segname + lVar100 + 0x1c);
          uVar65 = iVar68 * 3;
          if (0 < iVar68) {
            uVar97 = 0;
            pfVar76 = (float *)alStack_798[lVar81 + -1];
            uVar43 = uVar65;
            if ((int)uVar65 < 2) {
              uVar43 = 1;
            }
            psVar95 = (segment_command *)(ulong)uVar43;
            uVar98 = -(ulong)(uVar65 >> 0x1f) & 0xfffffffc00000000 | (ulong)uVar65 << 2;
            unaff_x28 = 0xd0;
            pfVar73 = pfVar76;
            do {
              iVar94 = (int)unaff_x28;
              psVar59 = (segment_command *)(psStack_a50->segname + (long)iVar94 + -8);
              if (uVar43 < 8) {
                psVar62 = (segment_command *)0x0;
              }
              else {
                lVar100 = uVar98 * uVar97;
                psVar46 = (segment_command *)((ulong)psVar95 & 0x7ffffff8);
                psVar78 = psVar59;
                pfVar67 = pfVar73;
                if ((segment_command *)((long)pfVar76 + (long)psVar95 * 4 + lVar100) <= psVar59 ||
                    psStack_a50->segname + (long)iVar94 + (long)psVar95 * 2 + -8 <=
                    (float *)((long)pfVar76 + lVar100)) {
                  do {
                    fVar116 = *pfVar67;
                    fVar169 = pfVar67[4];
                    iVar114 = (int)(pfVar67[5] + 0.5);
                    iVar115 = (int)(pfVar67[6] + 0.5);
                    iVar136 = (int)(pfVar67[7] + 0.5);
                    iVar142 = (int)(pfVar67[1] + 0.5);
                    iVar144 = (int)(pfVar67[2] + 0.5);
                    iVar146 = (int)(pfVar67[3] + 0.5);
                    uVar70 = CONCAT22((short)iVar142,(short)(int)(fVar116 + 0.5));
                    auVar150._0_8_ = CONCAT26((short)iVar146,CONCAT24((short)iVar144,uVar70));
                    auVar150._8_2_ = (short)(int)(fVar169 + 0.5);
                    auVar150._10_2_ = (short)iVar114;
                    auVar150._12_2_ = (short)iVar115;
                    auVar150._14_2_ = (short)iVar136;
                    param_5 = (char *)((long)psVar78->segname + 8);
                    *(long *)psVar78->segname = auVar150._8_8_;
                    psVar78->cmd = uVar70;
                    psVar78->cmdsize = (int)((ulong)auVar150._0_8_ >> 0x20);
                    auVar132._6_2_ = 0;
                    auVar132._0_6_ =
                         CONCAT15((char)((uint)iVar114 >> 8),
                                  CONCAT14((char)iVar114,(int)(fVar169 + 0.5))) & 0xffff0000ffff;
                    auVar132[8] = (undefined1)iVar115;
                    auVar132[9] = (undefined1)((uint)iVar115 >> 8);
                    auVar132._10_2_ = 0;
                    auVar132[0xc] = (undefined1)iVar136;
                    auVar132[0xd] = (undefined1)((uint)iVar136 >> 8);
                    auVar132._14_2_ = 0;
                    auVar171 = NEON_ucvtf(auVar132,4);
                    auVar139._6_2_ = 0;
                    auVar139._0_6_ =
                         CONCAT15((char)((uint)iVar142 >> 8),
                                  CONCAT14((char)iVar142,(int)(fVar116 + 0.5))) & 0xffff0000ffff;
                    auVar139[8] = (undefined1)iVar144;
                    auVar139[9] = (undefined1)((uint)iVar144 >> 8);
                    auVar139._10_2_ = 0;
                    auVar139[0xc] = (undefined1)iVar146;
                    auVar139[0xd] = (undefined1)((uint)iVar146 >> 8);
                    auVar139._14_2_ = 0;
                    auVar112 = NEON_ucvtf(auVar139,4);
                    param_6 = (segment_command *)(pfVar67 + 8);
                    *(long *)(pfVar67 + 2) = auVar112._8_8_;
                    *(long *)pfVar67 = auVar112._0_8_;
                    *(long *)(pfVar67 + 6) = auVar171._8_8_;
                    *(long *)(pfVar67 + 4) = auVar171._0_8_;
                    psVar61 = psVar46 + -1;
                    psVar46 = (segment_command *)&psVar61->nsects;
                    psVar78 = (segment_command *)param_5;
                    pfVar67 = (float *)param_6;
                    psVar62 = (segment_command *)((ulong)psVar95 & 0x7ffffff8);
                    if (&psVar61->nsects == (dword *)0x0) goto joined_r0x01532ecc;
                  } while( true );
                }
                psVar62 = (segment_command *)0x0;
              }
              do {
                param_5 = (char *)((long)psVar62 * 4);
                uVar65 = (uint)(pfVar73[(long)psVar62] + 0.5);
                param_6 = (segment_command *)(ulong)uVar65;
                *(short *)((long)psVar59->segname + (long)psVar62 * 2 + -8) = (short)uVar65;
                pfVar73[(long)psVar62] = (float)uVar65;
                psVar62 = (segment_command *)((long)&psVar62->cmd + 1);
joined_r0x01532ecc:
              } while (psVar62 != psVar95);
              unaff_x28 = (ulong)(uint)(iVar94 + iVar68 * 6);
              uVar97 = uVar97 + 1;
              pfVar73 = (float *)((long)pfVar73 + uVar98);
            } while (uVar97 != uVar110);
            goto LAB_01532f18;
          }
          iVar68 = iVar68 * 6 * uVar110;
          unaff_x28 = (ulong)(iVar68 + 0xd0);
          *(int *)(psStack_a50->segname + lVar81 * 4 + 0x3c) = iVar68;
        }
        iVar68 = (int)unaff_x28;
        if (-1 < iVar42) {
          puStack_ac0 = (undefined1 *)((long)&psStack_a50->cmdsize + 2);
          puStack_ac8 = (undefined1 *)((long)&psStack_a50->cmdsize + 3);
          psVar59 = (segment_command *)(psStack_ab0->segname + (uStack_a10 - 7));
          pcStack_a80 = psStack_a50->segname + 8;
          psVar62 = (segment_command *)auStack_2a0;
          unaff_x27 = (segment_command *)((long)&section_000000b8.reserved1 + 3);
          psVar95 = &sStack_9a0;
          psStack_a48 = psVar59;
          uStack_af8 = UNK_01a9c0b0._8_8_;
          uStack_b00 = (long)UNK_01a9c0b0;
          uStack_ae8 = UNK_01a9c0a0._8_8_;
          uStack_af0 = (long)UNK_01a9c0a0;
          uStack_b18 = UNK_017e9c20._8_8_;
          uStack_b20 = (long)UNK_017e9c20;
          uStack_b08 = UNK_01a9c0c0._8_8_;
          uStack_b10 = (long)UNK_01a9c0c0;
          uStack_b28 = UNK_017d5c60._8_8_;
          uStack_b30 = (long)UNK_017d5c60;
          lVar100 = (long)iVar68;
          builtin_strncpy(psStack_a50->segname + lVar100 + -8,"LEVEL",6);
          puStack_ac0[lVar100] = (char)uVar69 + '0';
          uVar97 = lVar100 + (((int)puStack_ac8 + iVar68) -
                             (int)(psStack_a50->segname + lVar100 + -8));
          uStack_a60 = uVar69 & 0xffffffff;
          if ((uVar97 & 7) == 0) {
            iVar42 = 0;
          }
          else {
            iVar42 = 8 - ((uint)uVar97 & 7);
            _bzero(psStack_a50->segname + (uVar97 - 8),iVar42);
          }
          psVar78 = psStack_ab0;
          uStack_a94 = iVar42 + (uint)uVar97;
          *(uint *)(psStack_a50->segname + uStack_a60 * 4 + 0x14) = uStack_a94;
          pcStack_a90 = psStack_a50->segname + (long)(int)uStack_a94 + -8;
          *(int *)((long)(pcStack_a90 + 0x24) + 0) = 0;
          *(int *)((long)(pcStack_a90 + 0x24) + 4) = 0;
          *(int *)((long)(pcStack_a90 + 0x1c) + 0) = 0;
          *(int *)((long)(pcStack_a90 + 0x1c) + 4) = 0;
          pcStack_a90[8] = '\0';
          pcStack_a90[9] = '\0';
          pcStack_a90[10] = '\0';
          pcStack_a90[0xb] = '\0';
          pcStack_a90[0xc] = '\0';
          pcStack_a90[0xd] = '\0';
          pcStack_a90[0xe] = '\0';
          pcStack_a90[0xf] = '\0';
          pcStack_a90[0] = '\0';
          pcStack_a90[1] = '\0';
          pcStack_a90[2] = '\0';
          pcStack_a90[3] = '\0';
          pcStack_a90[4] = '\0';
          pcStack_a90[5] = '\0';
          pcStack_a90[6] = '\0';
          pcStack_a90[7] = '\0';
          *(qword *)(pcStack_a90 + 0x18) = 0;
          *(qword *)(pcStack_a90 + 0x10) = 0;
          uVar69 = uVar93 & 0xffffffff;
          lStack_aa0 = alStack_798[uStack_a60 - 1];
          iVar42 = *(int *)(psStack_a50[1].segname + uStack_a60 * 4 + 0x1c);
          lStack_a88 = (long)iVar42;
          psStack_a78 = (segment_command *)
                        (long)*(int *)(psStack_a50[2].segname + uStack_a60 * 4 + -4);
          psVar46 = (segment_command *)(lStack_a88 * 3);
          uVar70 = 100;
          if (uStack_a60 != 0) {
            uVar70 = 0x14;
          }
          uStack_9b0 = CONCAT44(uStack_9b0._4_4_,uVar70);
          param_6 = &sStack_4a0;
          if (((iVar42 < 0x10) || ((___ZN2IC11CpuFeatures21__CPU_instruction_setE & 0x3ff) != 0x3ff)
              ) && ((iVar42 < 0x10 ||
                    ((___ZN2IC11CpuFeatures21__CPU_instruction_setE & 0xff) != 0xff)))) {
            if ((~(uint)___ZN2IC11CpuFeatures21__CPU_instruction_setE & 0x7f) == 0) {
              if (iVar42 < 8) {
LAB_015334a4:
                func_0x01537d50(lStack_a88,psStack_a78,psVar46,psStack_ab0);
                goto joined_r0x01533100;
              }
            }
            else if ((iVar42 < 8) ||
                    (((___ZN2IC11CpuFeatures21__CPU_instruction_setE ^ 0xffffffffffffffff) &
                     0x50000000000000) != 0 &&
                     ((___ZN2IC11CpuFeatures21__CPU_instruction_setE ^ 0xffffffffffffffff) &
                     0x30000000000000) != 0)) goto LAB_015334a4;
            func_0x01537b68(lStack_a88,psStack_a78,psVar46,psStack_ab0,
                            *(int *)(psStack_a50[1].segname + uVar69 * 4 + 0x1c),
                            *(undefined4 *)(psStack_a50[2].segname + uVar69 * 4 + -4),
                            *(int *)(psStack_a50[1].segname + uVar69 * 4 + 0x1c) * 3,
                            alStack_798[(uVar93 & 0xffffffff) - 1]);
          }
joined_r0x01533100:
          psStack_9a8 = (segment_command *)(ulong)(uStack_a94 + 0x2c);
          iVar42 = (int)lStack_a88;
          psStack_a28 = psVar46;
          if (uStack_a60 == 0) {
            *(int *)(pcStack_a90 + 0x18) = 0;
            *(int *)(pcStack_a90 + 0x20) = 0;
            *(int *)(pcStack_a90 + 0x28) = 0;
            if ((7 < iVar42) && ((___ZN2IC11CpuFeatures21__CPU_instruction_setE & 0x3ff) == 0x3ff))
            {
              func_0x0000f224(unaff_x22,lStack_aa0,psVar78,psVar46,psStack_a78,lStack_a88);
              goto LAB_0153359c;
            }
            if ((~(uint)___ZN2IC11CpuFeatures21__CPU_instruction_setE & 0x7f) == 0) {
              if (3 < iVar42) {
LAB_01533568:
                func_0x01530604(unaff_x22,lStack_aa0,psVar78,psVar46,psStack_a78,lStack_a88);
                goto LAB_0153359c;
              }
            }
            else if ((3 < iVar42) &&
                    (((___ZN2IC11CpuFeatures21__CPU_instruction_setE ^ 0xffffffffffffffff) &
                     0x50000000000000) == 0 ||
                     ((___ZN2IC11CpuFeatures21__CPU_instruction_setE ^ 0xffffffffffffffff) &
                     0x30000000000000) == 0)) goto LAB_01533568;
            func_0x01530308(unaff_x22,lStack_aa0,psVar78,psVar46,psStack_a78,lStack_a88);
LAB_0153359c:
            auVar9._8_8_ = lStack_a88;
            auVar9._0_8_ = unaff_x22;
            auVar7 = auVar9._0_12_;
            psVar78 = (segment_command *)(ulong)uStack_a94;
            iVar42 = (int)psStack_9a8;
            *(uint *)pcStack_a90 = iVar42 - uStack_a94;
            unaff_x23 = (segment_command *)(psStack_a50->segname + (long)iVar42 + -8);
            param_7 = (segment_command *)(ulong)(uint)((int)psStack_ab8 - iVar42);
            psVar64 = (segment_command *)(uStack_9b0 & 0xffffffff);
            uVar109 = 0x15335d8;
            psVar61 = psStack_a78;
            pcVar63 = pcStack_a90;
            goto __ZN5Proxy13tjpg_compressEPhiiiiPvi;
          }
          if ((7 < iVar42) && ((___ZN2IC11CpuFeatures21__CPU_instruction_setE & 0x3ff) == 0x3ff)) {
            func_0x0000f224(lStack_aa0,psVar78,unaff_x22,psVar45,pcStack_aa8,psVar46,lStack_a88,
                            psStack_a78);
            goto LAB_015331e4;
          }
          if ((~(uint)___ZN2IC11CpuFeatures21__CPU_instruction_setE & 0x7f) == 0) {
            if (3 < iVar42) {
LAB_015331a0:
              func_0x015301e4(lStack_aa0,psVar78,unaff_x22,psVar45,pcStack_aa8,psVar46,lStack_a88,
                              psStack_a78);
              goto LAB_015331e4;
            }
          }
          else if ((3 < iVar42) &&
                  (((___ZN2IC11CpuFeatures21__CPU_instruction_setE ^ 0xffffffffffffffff) &
                   0x50000000000000) == 0 ||
                   ((___ZN2IC11CpuFeatures21__CPU_instruction_setE ^ 0xffffffffffffffff) &
                   0x30000000000000) == 0)) goto LAB_015331a0;
          func_0x0152fdd0(lStack_aa0,psVar78,unaff_x22,psVar45,pcStack_aa8,psVar46,lStack_a88,
                          psStack_a78);
LAB_015331e4:
          auVar8._8_8_ = lStack_a88;
          auVar8._0_8_ = unaff_x22;
          auVar7 = auVar8._0_12_;
          *(int *)(pcStack_a90 + 0x14) = 0x2c;
          iVar42 = (int)psStack_9a8;
          unaff_x23 = (segment_command *)((char *)(long)iVar42 + (long)(psStack_a50->segname + -8));
          param_7 = (segment_command *)(ulong)(uint)((int)psStack_ab8 - iVar42);
          psVar64 = (segment_command *)&segment_command_00000020.flags;
          uVar109 = 0x1533220;
          pdVar33 = &dStack_b60;
          psVar61 = psStack_a78;
          pcVar63 = (char *)(long)iVar42;
          psVar78 = psStack_ab8;
          psVar95 = psVar46;
          goto __ZN5Proxy13tjpg_compressEPhiiiiPvi;
        }
        if (iStack_acc == 0) {
          psStack_b80 = (segment_command *)((long)&MACH_HEADER.magic + 1);
        }
        else {
          psVar59 = (segment_command *)(long)iVar68;
          __ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5writeEPKcl(plStack_ad8,psStack_a50);
          psStack_b80 = (segment_command *)
                        (ulong)(*(int *)((long)plVar51 + *(long *)(*plVar51 + -0x18) + 0x20) == 0);
        }
        unaff_x19 = psStack_ab0;
        param_7 = psStack_a50;
        _free(psStack_a50);
        _free(unaff_x19);
        unaff_x23 = psVar45;
        unaff_x24 = uVar69;
        unaff_x26 = pfVar108;
      }
    }
  }
  else {
    func_0x00574408("Saving proxy: invalid image format.");
    psStack_b80 = (segment_command *)0x0;
    psVar59 = param_3;
    psVar62 = param_4;
  }
  if (*(qword *)PTR____stack_chk_guard_01d15188 == qStack_90) {
    return psStack_b80;
  }
  auVar171 = ___stack_chk_fail();
  lStack_f58 = auVar171._8_8_;
  plVar51 = auVar171._0_8_;
  uStack_b68 = 0x1534768;
  ppuVar107 = &puStack_b70;
  ppsVar36 = &psStack_1050;
  ppsVar34 = &psStack_1050;
  ppsVar32 = &psStack_1050;
  alStack_bd0[0] = *(long *)PTR____stack_chk_guard_01d15188;
  psVar46 = (segment_command *)&MACH_HEADER.filetype;
  psVar61 = psVar62;
  psVar64 = (segment_command *)param_5;
  psVar57 = param_6;
  alStack_bd0[2] = unaff_x28;
  psStack_bb8 = unaff_x27;
  pfStack_bb0 = unaff_x26;
  psStack_ba8 = unaff_x25;
  uStack_ba0 = unaff_x24;
  psStack_b98 = unaff_x23;
  psStack_b90 = unaff_x22;
  psStack_b88 = unaff_x21;
  psStack_b78 = unaff_x19;
  puStack_b70 = puVar106;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(plVar51,&iStack_c94);
  if (((*(int *)((long)plVar51 + *(long *)(*plVar51 + -0x18) + 0x20) != 0) ||
      (iStack_c94 != 0x47504a53 || iStack_c90 != -0x35014542)) || (iStack_c8c - 0xc5U < 0xfffffff7))
  {
    psVar45 = (segment_command *)0x0;
    psVar101 = param_7;
    goto LAB_01534814;
  }
  psVar46 = (segment_command *)(ulong)(iStack_c8c - 0xc);
  lStack_fd8 = (long)iStack_c8c;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(plVar51,auStack_c88);
  psVar45 = (segment_command *)0x0;
  psVar101 = param_7;
  if (*(int *)((long)plVar51 + *(long *)(*plVar51 + -0x18) + 0x20) != 0 || 3 < auStack_c88[0])
  goto LAB_01534814;
  uVar110 = uStack_c84;
  if ((int)uStack_c84 < 0) {
    uVar110 = uStack_c84 + 1;
  }
  iVar42 = (int)psVar59;
  uStack_1010 = uStack_c84;
  uStack_1014 = uStack_c80;
  if (((0 < iVar42) && (iVar68 = (int)psVar62, 0 < iVar68)) && (iVar42 <= (int)uVar110 >> 1)) {
    psVar45 = (segment_command *)0x0;
    if ((int)uStack_c80 < 0) {
      uStack_c80 = uStack_c80 + 1;
    }
    if ((iVar68 <= (int)uStack_c80 >> 1) && (0 < iStack_c7c)) {
      psVar59 = (segment_command *)((long)&MACH_HEADER.magic + 1);
      uVar65 = (int)uStack_c80 >> 1;
      uVar110 = (int)uVar110 >> 1;
      do {
        uStack_1010 = uVar110;
        uStack_1014 = uVar65;
        psVar45 = psVar59;
        uVar110 = uStack_1010;
        if ((int)uStack_1010 < 0) {
          uVar110 = uStack_1010 + 1;
        }
        if ((int)uVar110 >> 1 < iVar42) break;
        uVar43 = uStack_1014;
        if ((int)uStack_1014 < 0) {
          uVar43 = uStack_1014 + 1;
        }
        psVar59 = (segment_command *)(ulong)((int)psVar45 + 1);
        uVar65 = (int)uVar43 >> 1;
        uVar110 = (int)uVar110 >> 1;
      } while (iVar68 <= (int)uVar43 >> 1 && (int)psVar45 < iStack_c7c);
    }
  }
  psVar64 = (segment_command *)((long)&MACH_HEADER.magic + 3);
  psVar57 = &segment_command_00000020;
  func_0x01195d64(lStack_f58);
  piStack_1008 = aiStack_c28 + (long)psVar45;
  lVar100 = (long)aiStack_c28[(long)psVar45] * (long)(int)auStack_c00[(long)psVar45];
  unaff_x22 = (segment_command *)(lVar100 * 3);
  iVar42 = (int)psVar45;
  if (iStack_c7c < iVar42) {
    iVar68 = 0;
    unaff_x21 = (segment_command *)0x0;
  }
  else {
    if ((uint)(iStack_c7c - iVar42) < 0xf) {
      iVar68 = 0;
      psVar59 = psVar45;
LAB_01534a14:
      iVar94 = (iStack_c7c - (int)psVar59) + 1;
      piVar74 = aiStack_c28 + (long)psVar59;
      do {
        iVar68 = iVar68 + piVar74[10] * *piVar74 * 0xc;
        iVar94 = iVar94 + -1;
        piVar74 = piVar74 + 1;
      } while (iVar94 != 0);
    }
    else {
      uVar93 = (ulong)(uint)(iStack_c7c - iVar42) + 1;
      uVar97 = uVar93 & 0x1fffffff0;
      psVar59 = (segment_command *)(psVar45->segname + (uVar97 - 8));
      puVar49 = (undefined8 *)((long)alStack_bd0 + (long)psVar45 * 4);
      iVar68 = 0;
      iVar94 = 0;
      iVar114 = 0;
      iVar115 = 0;
      uVar69 = uVar97;
      auVar171 = ZEXT816(0);
      auVar112 = ZEXT816(0);
      auVar120 = ZEXT816(0);
      do {
        iVar68 = iVar68 + *(int *)(puVar49 + -6) * (int)puVar49[-0xb] * 0xc;
        iVar94 = iVar94 + *(int *)((long)puVar49 + -0x2c) * (int)((ulong)puVar49[-0xb] >> 0x20) *
                          0xc;
        iVar114 = iVar114 + *(int *)(puVar49 + -5) * (int)puVar49[-10] * 0xc;
        iVar115 = iVar115 + *(int *)((long)puVar49 + -0x24) * (int)((ulong)puVar49[-10] >> 0x20) *
                            0xc;
        auVar126._0_4_ = auVar171._0_4_ + *(int *)(puVar49 + -4) * (int)puVar49[-9] * 0xc;
        auVar126._4_4_ =
             auVar171._4_4_ +
             *(int *)((long)puVar49 + -0x1c) * (int)((ulong)puVar49[-9] >> 0x20) * 0xc;
        auVar126._8_4_ = auVar171._8_4_ + *(int *)(puVar49 + -3) * (int)puVar49[-8] * 0xc;
        auVar126._12_4_ =
             auVar171._12_4_ +
             *(int *)((long)puVar49 + -0x14) * (int)((ulong)puVar49[-8] >> 0x20) * 0xc;
        auVar133._0_4_ = auVar112._0_4_ + *(int *)(puVar49 + -2) * (int)puVar49[-7] * 0xc;
        auVar133._4_4_ =
             auVar112._4_4_ +
             *(int *)((long)puVar49 + -0xc) * (int)((ulong)puVar49[-7] >> 0x20) * 0xc;
        auVar133._8_4_ = auVar112._8_4_ + *(int *)(puVar49 + -1) * (int)puVar49[-6] * 0xc;
        auVar133._12_4_ =
             auVar112._12_4_ +
             *(int *)((long)puVar49 + -4) * (int)((ulong)puVar49[-6] >> 0x20) * 0xc;
        auVar140._0_4_ = auVar120._0_4_ + (int)*puVar49 * (int)puVar49[-5] * 0xc;
        auVar140._4_4_ =
             auVar120._4_4_ +
             (int)((ulong)*puVar49 >> 0x20) * (int)((ulong)puVar49[-5] >> 0x20) * 0xc;
        auVar140._8_4_ = auVar120._8_4_ + (int)puVar49[1] * (int)puVar49[-4] * 0xc;
        auVar140._12_4_ =
             auVar120._12_4_ +
             (int)((ulong)puVar49[1] >> 0x20) * (int)((ulong)puVar49[-4] >> 0x20) * 0xc;
        puVar49 = puVar49 + 8;
        uVar69 = uVar69 - 0x10;
        auVar171 = auVar126;
        auVar112 = auVar133;
        auVar120 = auVar140;
      } while (uVar69 != 0);
      iVar68 = auVar140._0_4_ + auVar133._0_4_ + auVar126._0_4_ + iVar68 +
               auVar140._4_4_ + auVar133._4_4_ + auVar126._4_4_ + iVar94 +
               auVar140._8_4_ + auVar133._8_4_ + auVar126._8_4_ + iVar114 +
               auVar140._12_4_ + auVar133._12_4_ + auVar126._12_4_ + iVar115;
      if (uVar93 != uVar97) goto LAB_01534a14;
    }
    if ((uint)(iStack_c7c - iVar42) < 0xf) {
      unaff_x21 = (segment_command *)0x0;
      psVar59 = psVar45;
    }
    else {
      uVar93 = (ulong)(uint)(iStack_c7c - iVar42) + 1;
      uVar97 = uVar93 & 0x1fffffff0;
      psVar59 = (segment_command *)(psVar45->segname + (uVar97 - 8));
      piVar74 = aiStack_c58 + (long)psVar45;
      auVar171 = ZEXT816(0);
      auVar112 = ZEXT816(0);
      auVar120 = ZEXT816(0);
      auVar128 = ZEXT816(0);
      uVar69 = uVar97;
      do {
        auVar141._0_4_ = (int)*(undefined8 *)(piVar74 + 2) + piVar74[-8];
        auVar141._4_4_ = (int)((ulong)*(undefined8 *)(piVar74 + 2) >> 0x20) + piVar74[-7];
        auVar141._8_4_ = (int)*(undefined8 *)(piVar74 + 4) + piVar74[-6];
        auVar141._12_4_ = (int)((ulong)*(undefined8 *)(piVar74 + 4) >> 0x20) + piVar74[-5];
        auVar151._0_4_ = (int)*(undefined8 *)(piVar74 + 6) + piVar74[-4];
        auVar151._4_4_ = (int)((ulong)*(undefined8 *)(piVar74 + 6) >> 0x20) + piVar74[-3];
        auVar151._8_4_ = (int)*(undefined8 *)(piVar74 + 8) + piVar74[-2];
        auVar151._12_4_ = (int)((ulong)*(undefined8 *)(piVar74 + 8) >> 0x20) + piVar74[-1];
        auVar159._0_4_ = (int)*(undefined8 *)(piVar74 + 10) + *piVar74;
        auVar159._4_4_ = (int)((ulong)*(undefined8 *)(piVar74 + 10) >> 0x20) + piVar74[1];
        auVar159._8_4_ = (int)*(undefined8 *)(piVar74 + 0xc) + piVar74[2];
        auVar159._12_4_ = (int)((ulong)*(undefined8 *)(piVar74 + 0xc) >> 0x20) + piVar74[3];
        auVar166._0_4_ = (int)*(undefined8 *)(piVar74 + 0xe) + piVar74[4];
        auVar166._4_4_ = (int)((ulong)*(undefined8 *)(piVar74 + 0xe) >> 0x20) + piVar74[5];
        auVar166._8_4_ = (int)*(undefined8 *)(piVar74 + 0x10) + piVar74[6];
        auVar166._12_4_ = (int)((ulong)*(undefined8 *)(piVar74 + 0x10) >> 0x20) + piVar74[7];
        auVar171 = NEON_smax(auVar141,auVar171,4);
        auVar112 = NEON_smax(auVar151,auVar112,4);
        auVar120 = NEON_smax(auVar159,auVar120,4);
        auVar128 = NEON_smax(auVar166,auVar128,4);
        piVar74 = piVar74 + 0x10;
        uVar69 = uVar69 - 0x10;
      } while (uVar69 != 0);
      auVar171 = NEON_smax(auVar171,auVar112,4);
      auVar171 = NEON_smax(auVar171,auVar120,4);
      auVar171 = NEON_smax(auVar171,auVar128,4);
      uVar110 = NEON_smaxv(auVar171,4);
      unaff_x21 = (segment_command *)(ulong)uVar110;
      if (uVar93 == uVar97) goto LAB_01534b18;
    }
    iVar94 = (iStack_c7c - (int)psVar59) + 1;
    piVar74 = aiStack_c58 + (long)((long)&psVar59->cmd + 2);
    do {
      uVar110 = *piVar74 + piVar74[-10];
      if (*piVar74 + piVar74[-10] <= (int)(uint)unaff_x21) {
        uVar110 = (uint)unaff_x21;
      }
      unaff_x21 = (segment_command *)(ulong)uVar110;
      iVar94 = iVar94 + -1;
      piVar74 = piVar74 + 1;
    } while (iVar94 != 0);
  }
LAB_01534b18:
  unaff_x23 = (segment_command *)(ulong)(iStack_c7c < iVar42);
  iVar114 = auStack_c00[(long)psVar45] * 4;
  iVar94 = iVar114 + 0x1c;
  iVar114 = iVar114 + 0x23;
  if (-1 < iVar94) {
    iVar114 = iVar94;
  }
  lVar81 = (long)((iVar114 >> 3) + (int)unaff_x22 * 4 + iVar68 + (int)unaff_x21);
  psStack_fe8 = psVar45;
  psStack_f88 = (segment_command *)__Znam(lVar81 + 0x28);
  uStack_ffc = (uint)param_6;
  lStack_f80 = (long)psStack_f88->segname + lVar81 + 0x20;
  pcStack_ff0 = unaff_x22->segname + (long)((long)psStack_f88->segname + -0x10);
  pcStack_ff8 = pcStack_ff0 + (long)unaff_x22;
  unaff_x27 = (segment_command *)(pcStack_ff8 + (long)unaff_x22);
  pcStack_fb0 = unaff_x22->segname + (long)(unaff_x27->segname + -0x10);
  psVar61 = (segment_command *)param_5;
  psStack_fb8 = (segment_command *)(long)iStack_c7c;
  if (iStack_c7c >= iVar42) {
    unaff_x23 = (segment_command *)auStack_d38;
    pcVar63 = pcStack_fb0 + (long)unaff_x21;
    psVar62 = (segment_command *)(ulong)((iStack_c7c - (int)psStack_fe8) + 1);
    piVar74 = piStack_1008;
    pcVar104 = sStack_ce8.segname + (long)psStack_fe8 * 8 + -8;
    do {
      lVar88 = (long)piVar74[10] * (long)(*piVar74 * 3) * 4;
      auStack_d38._0_8_ = lStack_f80 - (long)pcVar63;
      psVar61 = (segment_command *)auStack_d38;
      pcStack_f48 = pcVar63;
      lVar81 = __ZNSt3__15alignEmmRPvRm(4,lVar88,(segment_command *)&pcStack_f48);
      piVar74 = piVar74 + 1;
      param_6 = (segment_command *)(pcVar104 + 8);
      *(long *)pcVar104 = lVar81;
      pcVar63 = (char *)(lVar88 + lVar81);
      uVar110 = (int)psVar62 - 1;
      psVar62 = (segment_command *)(ulong)uVar110;
      pcVar104 = (char *)param_6;
    } while (uVar110 != 0);
  }
  lStack_fd0 = func_0x0074b028();
  lVar81 = lStack_fd8;
  psVar46 = (segment_command *)(long)((int)unaff_x21 - (int)lStack_fd8);
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(plVar51,pcStack_fb0 + lStack_fd8);
  if (*(int *)((long)plVar51 + *(long *)(*plVar51 + -0x18) + 0x20) == 0) {
    uStack_1028 = 1;
    if ((int)psStack_fe8 <= (int)psStack_fb8) {
      psStack_fe0 = (segment_command *)(long)(int)psStack_fe8;
      lStack_1030 = lVar100 * 0xc;
      pdStack_1038 = (dword *)((long)psStack_f88->segname + (lVar100 * 3 + 6) * 4);
      unaff_x23 = (segment_command *)0x100000000;
      psVar59 = psStack_fb8;
      do {
        psVar62 = psVar59;
        lVar100 = func_0x0074b028();
        pcVar63 = (char *)((long)&psVar62->cmd + 1);
        *(double *)(auStack_d38 + (long)pcVar63 * 8) = (double)(ulong)(lVar100 - lStack_fd0) * 1e-06
        ;
        uVar93 = (ulong)auStack_c78[(long)psVar62];
        unaff_x22 = (segment_command *)(pcStack_fb0 + uVar93);
        param_6 = *(segment_command **)(sStack_ce8.segname + (long)psVar62 * 8 + -8);
        iVar42 = aiStack_c28[(long)psVar62];
        psStack_f70 = (segment_command *)(ulong)auStack_c00[(long)psVar62];
        uStack_fa0 = CONCAT44(uStack_fa0._4_4_,iVar42);
        uVar110 = iVar42 * 3;
        psStack_fa8 = (segment_command *)(ulong)uVar110;
        psStack_fc0 = psVar62;
        if (psVar62 != psStack_fb8) {
          uStack_1020 = *(undefined8 *)(sStack_ce8.segname + (long)&psVar62->cmd * 8);
          iStack_100c = aiStack_c28[(long)pcVar63];
          uStack_1024 = auStack_c00[(long)pcVar63];
          uVar110 = unaff_x22->cmdsize;
          param_5 = (char *)(ulong)uVar110;
          bVar37 = (uStack_ffc & psVar62 == psStack_fe0) == 0;
          uStack_fc4 = 0;
          if (bVar37) {
            uStack_fc4 = (uint)unaff_x22->fileoff;
          }
          psVar78 = (segment_command *)(long)*(int *)((long)&unaff_x22->vmsize + 4);
          uVar65 = 0;
          if (bVar37) {
            uVar65 = (uint)unaff_x22->vmsize;
          }
          unaff_x25 = (segment_command *)(ulong)uVar65;
          uVar93 = (ulong)*(int *)((long)&unaff_x22->vmaddr + 4);
          uVar43 = 0;
          if (bVar37) {
            uVar43 = (uint)unaff_x22->vmaddr;
          }
          psVar62 = (segment_command *)(ulong)uVar43;
          pcStack_f48 = (char *)0x0;
          cStack_f40 = '\x01';
          if ((int)uVar43 < 1) {
            if (0 < (int)uVar65) {
              param_7 = unaff_x25;
              func_0x01537114((segment_command *)&pcStack_f48,pcStack_ff0,iVar42,psStack_f70,
                              psStack_fa8,unaff_x22->segname + (uVar93 - 8));
            }
            if ((int)uStack_fc4 < 1) {
              auVar10._8_4_ = uVar43;
              auVar10._0_8_ = &sStack_ce8;
              auVar10._12_4_ = 0;
              if (0 < (int)uVar110) {
                param_7 = (segment_command *)param_5;
                func_0x01537114((segment_command *)&pcStack_f48,unaff_x27,uStack_fa0 & 0xffffffff,
                                psStack_f70,psStack_fa8,
                                unaff_x22->segname + (long)(int)unaff_x22->cmd + -8);
              }
              psVar50 = (segment_command *)&pcStack_f48;
              uVar109 = 0x1534fa8;
              goto __ZN5Proxy13tjpg_plan_runEP22tjpg_plan_decompress_t;
            }
            psVar59 = (segment_command *)
                      ((long)psVar78->segname + (long)(unaff_x22->segname + -0x10));
            auVar174._8_8_ = pcStack_ff8;
            auVar174._0_8_ = (segment_command *)&pcStack_f48;
            param_7 = (segment_command *)(ulong)uStack_fc4;
            uVar109 = 0x1534f70;
            psVar64 = psStack_fa8;
            goto __ZN5Proxy13tjpg_plan_addEP22tjpg_plan_decompress_tPhiiiPKvi;
          }
          psVar59 = (segment_command *)
                    (unaff_x22->segname + (long)*(int *)(unaff_x22->segname + 0xc) + -8);
          auVar174._8_8_ = psStack_f88;
          auVar174._0_8_ = (segment_command *)&pcStack_f48;
          uVar109 = 0x1534f1c;
          ppsVar34 = &psStack_1050;
          psVar64 = psStack_fa8;
          param_7 = psVar62;
          goto __ZN5Proxy13tjpg_plan_addEP22tjpg_plan_decompress_tPhiiiPKvi;
        }
        if ((0 < (int)auStack_c00[(long)psVar62]) && (0 < iVar42)) {
          lVar100 = 0;
          psVar59 = (segment_command *)0x0;
          uVar65 = uVar110;
          if ((int)uVar110 < 2) {
            uVar65 = 1;
          }
          psVar45 = (segment_command *)(ulong)uVar65;
          uVar69 = -(ulong)(uVar110 >> 0x1f) & 0xfffffffc00000000 | (long)psStack_fa8 << 2;
          uVar97 = -(ulong)(uVar110 >> 0x1f) & 0xfffffffe00000000 | (long)psStack_fa8 << 1;
          psVar95 = (segment_command *)((ulong)psVar45 & 0x7fffffe0);
          pdVar58 = &param_6->nsects;
          puVar47 = (ushort *)((long)pdStack_1038 + uVar93);
          do {
            if ((uVar65 < 0x20) ||
               (lVar81 = uVar69 * (long)psVar59,
               psVar57 = (segment_command *)(param_6->segname + (long)psVar45 * 4 + lVar81 + -8),
               puVar60 = puVar47, psVar61 = (segment_command *)pdVar58, psVar46 = psVar95,
               param_6->segname + lVar81 + -8 <
               (undefined1 *)
               ((long)psStack_f88->segname +
               uVar97 * (long)psVar59 + lStack_1030 + uVar93 + (long)psVar45 * 2 + -8) &&
               (segment_command *)
               ((long)psStack_f88->segname + uVar97 * (long)psVar59 + lStack_1030 + uVar93 + -8) <
               psVar57)) {
              psVar46 = (segment_command *)0x0;
LAB_01534e64:
              lVar81 = (long)psVar45 - (long)psVar46;
              pcVar63 = param_6->segname + (long)psVar46->segname * 4 + lVar100 * 4 + -0x28;
              psVar46 = (segment_command *)(unaff_x22->segname + (long)psVar46 * 2 + -8);
              do {
                psVar64 = (segment_command *)((long)&psVar46->cmd + 2);
                psVar57 = (segment_command *)(ulong)(ushort)psVar46->cmd;
                psVar61 = (segment_command *)(pcVar63 + 4);
                *(float *)pcVar63 = (float)(long)psVar57;
                lVar81 = lVar81 + -1;
                pcVar63 = (char *)psVar61;
                psVar46 = psVar64;
              } while (lVar81 != 0);
            }
            else {
              do {
                auVar127._2_2_ = 0;
                auVar127._0_2_ = puVar60[-0x10];
                auVar127._4_2_ = puVar60[-0xf];
                auVar127._6_2_ = 0;
                auVar127._8_2_ = puVar60[-0xe];
                auVar127._10_2_ = 0;
                auVar127._12_2_ = puVar60[-0xd];
                auVar127._14_2_ = 0;
                auVar171 = *(undefined1 (*) [16])(puVar60 + 8);
                auVar128 = NEON_ucvtf(auVar127,4);
                auVar111._2_2_ = 0;
                auVar111._0_2_ = puVar60[-0xc];
                auVar111._4_2_ = puVar60[-0xb];
                auVar111._6_2_ = 0;
                auVar111._8_2_ = puVar60[-10];
                auVar111._10_2_ = 0;
                auVar111._12_2_ = puVar60[-9];
                auVar111._14_2_ = 0;
                auVar112 = NEON_ucvtf(auVar111,4);
                auVar152._2_2_ = 0;
                auVar152._0_2_ = puVar60[-8];
                auVar152._4_2_ = puVar60[-7];
                auVar152._6_2_ = 0;
                auVar152._8_2_ = puVar60[-6];
                auVar152._10_2_ = 0;
                auVar152._12_2_ = puVar60[-5];
                auVar152._14_2_ = 0;
                auVar153 = NEON_ucvtf(auVar152,4);
                auVar119._2_2_ = 0;
                auVar119._0_2_ = puVar60[-4];
                auVar119._4_2_ = puVar60[-3];
                auVar119._6_2_ = 0;
                auVar119._8_2_ = puVar60[-2];
                auVar119._10_2_ = 0;
                auVar119._12_2_ = puVar60[-1];
                auVar119._14_2_ = 0;
                auVar120 = NEON_ucvtf(auVar119,4);
                auVar160._2_2_ = 0;
                auVar160._0_2_ = *puVar60;
                auVar160._4_2_ = puVar60[1];
                auVar160._6_2_ = 0;
                auVar160._8_2_ = puVar60[2];
                auVar160._10_2_ = 0;
                auVar160._12_2_ = puVar60[3];
                auVar160._14_2_ = 0;
                auVar161 = NEON_ucvtf(auVar160,4);
                auVar134._2_2_ = 0;
                auVar134._0_2_ = puVar60[4];
                auVar134._4_2_ = puVar60[5];
                auVar134._6_2_ = 0;
                auVar134._8_2_ = puVar60[6];
                auVar134._10_2_ = 0;
                auVar134._12_2_ = puVar60[7];
                auVar134._14_2_ = 0;
                auVar135 = NEON_ucvtf(auVar134,4);
                auVar167._2_2_ = 0;
                auVar167._0_2_ = auVar171._0_2_;
                auVar167._4_2_ = auVar171._2_2_;
                auVar167._6_2_ = 0;
                auVar167._8_2_ = auVar171._4_2_;
                auVar167._10_2_ = 0;
                auVar167._12_2_ = auVar171._6_2_;
                auVar167._14_2_ = 0;
                auVar168 = NEON_ucvtf(auVar167,4);
                *(long *)((long)psVar61 + -0x38) = auVar128._8_8_;
                ((segment_command *)((long)psVar61 + -0x40))->cmd = (int)auVar128._0_8_;
                ((segment_command *)((long)psVar61 + -0x40))->cmdsize =
                     (int)((ulong)auVar128._0_8_ >> 0x20);
                *(qword *)((long)psVar61 + -0x28) = auVar112._8_8_;
                *(long *)((long)psVar61 + -0x30) = auVar112._0_8_;
                auVar113._2_2_ = 0;
                auVar113._0_2_ = auVar171._8_2_;
                auVar113._4_2_ = auVar171._10_2_;
                auVar113._6_2_ = 0;
                auVar113._8_2_ = auVar171._12_2_;
                auVar113._10_2_ = 0;
                auVar113._12_2_ = auVar171._14_2_;
                auVar113._14_2_ = 0;
                *(qword *)((long)psVar61 + -0x18) = auVar153._8_8_;
                *(qword *)((long)psVar61 + -0x20) = auVar153._0_8_;
                *(long *)((long)psVar61 + -8) = auVar120._8_8_;
                *(qword *)((long)psVar61 + -0x10) = auVar120._0_8_;
                *(long *)((long)psVar61 + 8) = auVar161._8_8_;
                *(long *)psVar61 = auVar161._0_8_;
                *(long *)((long)psVar61 + 0x18) = auVar135._8_8_;
                *(long *)((long)psVar61 + 0x10) = auVar135._0_8_;
                auVar171 = NEON_ucvtf(auVar113,4);
                *(long *)((long)psVar61 + 0x28) = auVar168._8_8_;
                *(long *)((long)psVar61 + 0x20) = auVar168._0_8_;
                *(long *)((long)psVar61 + 0x38) = auVar171._8_8_;
                *(long *)((long)psVar61 + 0x30) = auVar171._0_8_;
                psVar61 = (segment_command *)((long)psVar61 + 0x80);
                psVar78 = psVar46 + -1;
                puVar60 = puVar60 + 0x20;
                psVar46 = (segment_command *)&psVar78->fileoff;
              } while (&psVar78->fileoff != (qword *)0x0);
              psVar64 = psVar95;
              psVar46 = psVar95;
              if (psVar95 != psVar45) goto LAB_01534e64;
            }
            psVar59 = (segment_command *)((long)&psVar59->cmd + 1);
            pdVar58 = (dword *)((long)pdVar58 + uVar69);
            puVar47 = (ushort *)((long)puVar47 + uVar97);
            lVar100 = lVar100 + (int)uVar110;
            unaff_x22 = (segment_command *)(unaff_x22->segname + (uVar97 - 8));
            psVar46 = psStack_f70;
          } while (psVar59 != psStack_f70);
        }
        lVar81 = lStack_fd8;
        psVar59 = (segment_command *)((long)&psVar62[-1].flags + 3);
      } while ((long)psStack_fe0 < (long)psVar62);
    }
    param_5 = (char *)psStack_fe8;
    uStack_1028 = 1;
    lVar100 = func_0x0074b028();
    psVar59 = psStack_f88;
    psVar62 = psStack_fb8;
    *(double *)(auStack_d38 + (long)param_5 * 8) = (double)(ulong)(lVar100 - lStack_fd0) * 1e-06;
    if ((uStack_1028 & 1) == 0) {
LAB_01535e04:
      psVar45 = (segment_command *)0x0;
    }
    else {
      auVar112 = ZEXT816(0x3f800000);
      auVar120 = ZEXT816(0x3f800000);
      auVar171 = ZEXT816(0x3f800000);
      if ((0xc3 < (int)lVar81) && (1 < auStack_c88[0])) {
        fVar169 = (float)NEON_ucvtf((uint)uStack_bd8);
        auVar112 = ZEXT416((uint)(32.0 / fVar169));
        fVar169 = (float)NEON_ucvtf((uint)uStack_bd6);
        auVar120 = ZEXT416((uint)(32.0 / fVar169));
        fVar169 = (float)NEON_ucvtf((uint)uStack_bd4);
        auVar171 = ZEXT416((uint)(32.0 / fVar169));
      }
      if (auStack_c88[0] < 3) {
        uStack_fa0 = auVar120._0_8_;
        pfVar108 = *(float **)(sStack_ce8.segname + (long)param_5 * 8 + -8);
        uStack_f98 = auVar120._8_8_;
        lStack_f80 = auVar171._0_8_;
        uStack_f78 = auVar171._8_8_;
        psStack_f70 = auVar112._0_8_;
        uStack_f68 = auVar112._8_8_;
        puVar48 = (undefined2 *)func_0x01196ea8(lStack_f58);
        psVar46 = (segment_command *)(ulong)uStack_1010;
        if ((0 < (int)uStack_1014) && (0 < (int)uStack_1010)) {
          uVar93 = 0;
          iVar42 = *piStack_1008;
          uVar69 = *(ulong *)(lStack_f58 + 0x38);
          psVar45 = (segment_command *)((ulong)psVar46 & 0xfffffff8);
          do {
            fVar169 = SUB84(psStack_f70,0);
            fVar137 = (float)uStack_fa0;
            fVar116 = (float)lStack_f80;
            psVar95 = psVar45;
            pfVar76 = pfVar108;
            puVar91 = puVar48;
            if (uStack_1010 < 8) {
              psVar95 = (segment_command *)0x0;
LAB_01535b10:
              lVar81 = (long)psVar46 - (long)psVar95;
              lVar100 = (long)psVar95 * 0xc;
              puVar91 = puVar48 + (long)psVar95 * 3;
              do {
                pfVar76 = (float *)((long)pfVar108 + lVar100);
                fVar170 = pfVar76[1];
                fVar117 = pfVar76[2];
                *puVar91 = (short)(int)(fVar169 * *pfVar76);
                puVar91[1] = (short)(int)(fVar137 * fVar170);
                puVar91[2] = (short)(int)(fVar116 * fVar117);
                lVar100 = lVar100 + 0xc;
                puVar91 = puVar91 + 3;
                lVar81 = lVar81 + -1;
              } while (lVar81 != 0);
            }
            else {
              do {
                fVar118 = pfVar76[1];
                fVar125 = pfVar76[2];
                fVar170 = pfVar76[3];
                fVar121 = pfVar76[4];
                fVar129 = pfVar76[5];
                fVar117 = pfVar76[6];
                fVar122 = pfVar76[7];
                fVar130 = pfVar76[8];
                fVar124 = pfVar76[9];
                fVar123 = pfVar76[10];
                fVar131 = pfVar76[0xb];
                fVar138 = pfVar76[0xc];
                fVar148 = pfVar76[0xd];
                fVar157 = pfVar76[0xe];
                fVar143 = pfVar76[0xf];
                fVar154 = pfVar76[0x10];
                fVar162 = pfVar76[0x11];
                fVar145 = pfVar76[0x12];
                fVar155 = pfVar76[0x13];
                fVar163 = pfVar76[0x14];
                fVar147 = pfVar76[0x15];
                fVar156 = pfVar76[0x16];
                fVar164 = pfVar76[0x17];
                *puVar91 = (short)(int)(*pfVar76 * fVar169);
                puVar91[1] = (short)(int)(fVar118 * fVar137);
                puVar91[2] = (short)(int)(fVar125 * fVar116);
                puVar91[3] = (short)(int)(fVar170 * fVar169);
                puVar91[4] = (short)(int)(fVar121 * fVar137);
                puVar91[5] = (short)(int)(fVar129 * fVar116);
                puVar91[6] = (short)(int)(fVar117 * fVar169);
                puVar91[7] = (short)(int)(fVar122 * fVar137);
                puVar91[8] = (short)(int)(fVar130 * fVar116);
                puVar91[9] = (short)(int)(fVar124 * fVar169);
                puVar91[10] = (short)(int)(fVar123 * fVar137);
                puVar91[0xb] = (short)(int)(fVar131 * fVar116);
                puVar91[0xc] = (short)(int)(fVar138 * fVar169);
                puVar91[0xd] = (short)(int)(fVar148 * fVar137);
                puVar91[0xe] = (short)(int)(fVar157 * fVar116);
                puVar91[0xf] = (short)(int)(fVar143 * fVar169);
                puVar91[0x10] = (short)(int)(fVar154 * fVar137);
                puVar91[0x11] = (short)(int)(fVar162 * fVar116);
                puVar91[0x12] = (short)(int)(fVar145 * fVar169);
                puVar91[0x13] = (short)(int)(fVar155 * fVar137);
                puVar91[0x14] = (short)(int)(fVar163 * fVar116);
                puVar91[0x15] = (short)(int)(fVar147 * fVar169);
                puVar91[0x16] = (short)(int)(fVar156 * fVar137);
                puVar91[0x17] = (short)(int)(fVar164 * fVar116);
                psVar78 = psVar95 + -1;
                psVar95 = (segment_command *)&psVar78->nsects;
                pfVar76 = pfVar76 + 0x18;
                puVar91 = puVar91 + 0x18;
              } while (&psVar78->nsects != (dword *)0x0);
              psVar95 = psVar45;
              if (psVar45 != psVar46) goto LAB_01535b10;
            }
            uVar93 = uVar93 + 1;
            puVar48 = (undefined2 *)((long)puVar48 + (uVar69 & 0xfffffffffffffffe));
            pfVar108 = pfVar108 + (uint)(iVar42 * 3);
          } while (uVar93 != uStack_1014);
        }
      }
      else {
        if (auStack_c88[0] != 3) {
          psStack_1050 = (segment_command *)(ulong)auStack_c88[0];
          func_0x00574408("Proxy::LoadSturdyJPEG: unsupported proxy version (%d)");
          goto LAB_01535e04;
        }
        uStack_fa0 = auVar120._0_8_;
        pfVar108 = *(float **)(sStack_ce8.segname + (long)param_5 * 8 + -8);
        uStack_f98 = auVar120._8_8_;
        lStack_f80 = auVar171._0_8_;
        uStack_f78 = auVar171._8_8_;
        psStack_f70 = auVar112._0_8_;
        uStack_f68 = auVar112._8_8_;
        puVar48 = (undefined2 *)func_0x01196ea8(lStack_f58);
        psVar46 = (segment_command *)(ulong)uStack_1010;
        if ((0 < (int)uStack_1014) && (0 < (int)uStack_1010)) {
          uVar93 = 0;
          iVar42 = *piStack_1008;
          uVar69 = *(ulong *)(lStack_f58 + 0x38);
          fVar169 = SUB84(psStack_f70,0) / 65535.0;
          fVar116 = (float)uStack_fa0 / 65535.0;
          psVar45 = (segment_command *)((ulong)psVar46 & 0xfffffff8);
          fVar137 = (float)lStack_f80 / 65535.0;
          do {
            psVar95 = psVar45;
            pfVar76 = pfVar108;
            puVar91 = puVar48;
            if (uStack_1010 < 8) {
              psVar95 = (segment_command *)0x0;
LAB_01535c9c:
              lVar81 = (long)psVar46 - (long)psVar95;
              lVar100 = (long)psVar95 * 0xc;
              puVar91 = puVar48 + (long)psVar95 * 3;
              do {
                pfVar76 = (float *)((long)pfVar108 + lVar100);
                fVar170 = pfVar76[1];
                fVar117 = pfVar76[2];
                *puVar91 = (short)(int)(fVar169 * *pfVar76 * *pfVar76);
                puVar91[1] = (short)(int)(fVar116 * fVar170 * fVar170);
                puVar91[2] = (short)(int)(fVar137 * fVar117 * fVar117);
                lVar100 = lVar100 + 0xc;
                puVar91 = puVar91 + 3;
                lVar81 = lVar81 + -1;
              } while (lVar81 != 0);
            }
            else {
              do {
                fVar138 = pfVar76[2];
                fVar123 = pfVar76[3];
                fVar143 = pfVar76[5];
                fVar125 = pfVar76[6];
                fVar130 = pfVar76[7];
                fVar145 = pfVar76[8];
                fVar129 = pfVar76[9];
                fVar131 = pfVar76[10];
                fVar147 = pfVar76[0xb];
                fVar170 = pfVar76[0xc];
                fVar148 = pfVar76[0xe];
                fVar117 = pfVar76[0xf];
                fVar154 = pfVar76[0x11];
                fVar124 = pfVar76[0x12];
                fVar121 = pfVar76[0x13];
                fVar155 = pfVar76[0x14];
                fVar118 = pfVar76[0x15];
                fVar122 = pfVar76[0x16];
                fVar156 = pfVar76[0x17];
                uVar98 = (ulong)CONCAT24((short)(int)(pfVar76[0x10] * pfVar76[0x10] * fVar116),
                                         (int)(pfVar76[0xd] * pfVar76[0xd] * fVar116)) &
                         0xffffffff0000ffff;
                uVar97 = (ulong)CONCAT24((short)(int)(pfVar76[4] * pfVar76[4] * fVar116),
                                         (int)(pfVar76[1] * pfVar76[1] * fVar116)) &
                         0xffffffff0000ffff;
                *puVar91 = (short)(int)(*pfVar76 * *pfVar76 * fVar169);
                puVar91[1] = (short)uVar97;
                puVar91[2] = (short)(int)(fVar138 * fVar138 * fVar137);
                puVar91[3] = (short)(int)(fVar123 * fVar123 * fVar169);
                puVar91[4] = (short)(uVar97 >> 0x20);
                puVar91[5] = (short)(int)(fVar143 * fVar143 * fVar137);
                puVar91[6] = (short)(int)(fVar125 * fVar125 * fVar169);
                puVar91[7] = (short)(int)(fVar130 * fVar130 * fVar116);
                puVar91[8] = (short)(int)(fVar145 * fVar145 * fVar137);
                puVar91[9] = (short)(int)(fVar129 * fVar129 * fVar169);
                puVar91[10] = (short)(int)(fVar131 * fVar131 * fVar116);
                puVar91[0xb] = (short)(int)(fVar147 * fVar147 * fVar137);
                puVar91[0xc] = (short)(int)(fVar170 * fVar170 * fVar169);
                puVar91[0xd] = (short)uVar98;
                puVar91[0xe] = (short)(int)(fVar148 * fVar148 * fVar137);
                puVar91[0xf] = (short)(int)(fVar117 * fVar117 * fVar169);
                puVar91[0x10] = (short)(uVar98 >> 0x20);
                puVar91[0x11] = (short)(int)(fVar154 * fVar154 * fVar137);
                puVar91[0x12] = (short)(int)(fVar124 * fVar124 * fVar169);
                puVar91[0x13] = (short)(int)(fVar121 * fVar121 * fVar116);
                puVar91[0x14] = (short)(int)(fVar155 * fVar155 * fVar137);
                puVar91[0x15] = (short)(int)(fVar118 * fVar118 * fVar169);
                puVar91[0x16] = (short)(int)(fVar122 * fVar122 * fVar116);
                puVar91[0x17] = (short)(int)(fVar156 * fVar156 * fVar137);
                psVar78 = psVar95 + -1;
                psVar95 = (segment_command *)&psVar78->nsects;
                pfVar76 = pfVar76 + 0x18;
                puVar91 = puVar91 + 0x18;
              } while (&psVar78->nsects != (dword *)0x0);
              psVar95 = psVar45;
              if (psVar45 != psVar46) goto LAB_01535c9c;
            }
            uVar93 = uVar93 + 1;
            puVar48 = (undefined2 *)((long)puVar48 + (uVar69 & 0xfffffffffffffffe));
            pfVar108 = pfVar108 + (uint)(iVar42 * 3);
          } while (uVar93 != uStack_1014);
        }
      }
      if (__DEBUG_DISK_LATENCY != 0) {
        lVar100 = func_0x0074b028();
        unaff_x22 = (segment_command *)((long)&psVar62->cmd + 1);
        dStack_1048 = *(double *)(auStack_d38 + (long)unaff_x22 * 8) * 1000.0;
        psStack_1050 = unaff_x21;
        func_0x00574108("Loaded %i bytes in %.2f ms");
        if ((int)param_5 <= (int)psVar62) {
          unaff_x21 = (segment_command *)(long)(int)psStack_fe8;
          unaff_x23 = (segment_command *)auStack_d38;
          plVar51 = (long *)0x408f400000000000;
          param_5 = "Level %i loaded in %.2f ms";
          psVar45 = psVar62;
          do {
            dStack_1048 = (*(double *)((long)unaff_x23->segname + ((long)psVar45 * 2 + -2) * 4) -
                          *(double *)(auStack_d38 + (long)psVar45 * 8 + 8)) * 1000.0;
            psStack_1050 = psVar45;
            func_0x00574108("Level %i loaded in %.2f ms");
            psVar62 = (segment_command *)((long)&psVar45[-1].flags + 3);
            bVar37 = (long)unaff_x21 < (long)psVar45;
            psVar45 = psVar62;
          } while (bVar37);
        }
        psStack_1050 = (segment_command *)(ulong)(uint)((int)unaff_x22 - (int)psStack_fe8);
        dStack_1048 = (double)(ulong)(lVar100 - lStack_fd0) * 1e-06 * 1000.0;
        func_0x00574108("Loaded %i levels in %.2f ms");
      }
      psVar45 = (segment_command *)((long)&MACH_HEADER.magic + 1);
    }
  }
  else {
    psVar45 = (segment_command *)0x0;
    param_5 = (char *)psStack_fe8;
    psVar59 = psStack_f88;
  }
  __ZdlPv(psVar59);
  psVar101 = param_7;
LAB_01534814:
  if (*(long *)PTR____stack_chk_guard_01d15188 == alStack_bd0[0]) {
    return psVar45;
  }
  uVar109 = ___stack_chk_fail();
  __ZdlPv(psStack_f88);
  uVar109 = __Unwind_Resume(uVar109);
  __ZdlPv(psStack_f88);
  uVar109 = __Unwind_Resume(uVar109);
  __ZdlPv(psStack_f88);
  uVar109 = __Unwind_Resume(uVar109);
  __ZdlPv(psStack_f88);
  uVar109 = __Unwind_Resume(uVar109);
  __ZdlPv(psStack_f88);
  uVar109 = __Unwind_Resume(uVar109);
  __ZdlPv(psStack_f88);
  uVar109 = __Unwind_Resume(uVar109);
  __ZdlPv(psStack_f88);
  uVar109 = __Unwind_Resume(uVar109);
  __ZdlPv(psStack_f88);
  uVar109 = __Unwind_Resume(uVar109);
  __ZdlPv(psStack_f88);
  uVar109 = __Unwind_Resume(uVar109);
  __ZdlPv(psStack_f88);
  uVar109 = __Unwind_Resume(uVar109);
  __ZdlPv(psStack_f88);
  uVar109 = __Unwind_Resume(uVar109);
  __ZdlPv(psStack_f88);
  uVar109 = __Unwind_Resume(uVar109);
  __ZdlPv(psStack_f88);
  uVar109 = __Unwind_Resume(uVar109);
  __ZdlPv(psStack_f88);
  uVar93 = __Unwind_Resume(uVar109);
  __ZdlPv(psStack_f88);
  __Unwind_Resume(uVar93);
  uVar109 = 0x1535f40;
  auVar172 = __Unwind_Resume();
__ZN5Proxy13jpeg_compressEPhiiiiPvi:
  psVar56 = auVar172._8_8_;
  *(ulong *)((long)ppsVar32 + -0x70) = unaff_d9;
  *(ulong *)((long)ppsVar32 + -0x68) = unaff_d8;
  *(segment_command **)((long)ppsVar32 + -0x60) = param_6;
  *(segment_command **)((long)ppsVar32 + -0x58) = unaff_x27;
  *(segment_command **)((long)ppsVar32 + -0x50) = psVar59;
  *(segment_command **)((long)ppsVar32 + -0x48) = psVar62;
  *(long **)((long)ppsVar32 + -0x40) = plVar51;
  *(segment_command **)((long)ppsVar32 + -0x38) = unaff_x23;
  *(segment_command **)((long)ppsVar32 + -0x30) = unaff_x22;
  *(segment_command **)((long)ppsVar32 + -0x28) = unaff_x21;
  *(char **)((long)ppsVar32 + -0x20) = param_5;
  *(ulong *)((long)ppsVar32 + -0x18) = uVar93;
  *(undefined1 ***)((long)ppsVar32 + -0x10) = ppuVar107;
  *(undefined8 *)((long)ppsVar32 + -8) = uVar109;
  *(undefined8 *)((long)ppsVar32 + -0x78) = *(undefined8 *)PTR____stack_chk_guard_01d15188;
  psVar62 = (segment_command *)((long)ppsVar32 + -0x468);
  psVar78 = psVar46;
  psVar95 = psVar61;
  psVar59 = psVar64;
  psVar45 = psVar57;
  param_7 = psVar101;
  puVar49 = (undefined8 *)func_0x00fc9cf0(psVar62);
  *(undefined8 **)((long)ppsVar32 + -0x300) = puVar49;
  *puVar49 = 0x15360fc;
  iVar42 = _setjmp((undefined1 *)((long)ppsVar32 + -0x3c0));
  if (iVar42 == 1) {
LAB_01535fbc:
    psVar92 = (segment_command *)0xffffffff;
  }
  else {
    psVar62 = (segment_command *)((long)ppsVar32 + -0x300);
    func_0x00fb2594(psVar62,0x50,0x288);
    func_0x00720d10(psVar62,psVar57,psVar101);
    *(int *)((long)ppsVar32 + -0x294) = auVar172._8_4_;
    *(int *)((long)ppsVar32 + -0x290) = (int)psVar46;
    unaff_d8 = 0x100000001;
    *(undefined8 *)((long)ppsVar32 + -0x28c) = 0x100000001;
    func_0x00fc1fd0(psVar62);
    *(undefined8 *)(*(long *)((long)ppsVar32 + -600) + 8) = 0x100000001;
    psVar78 = (segment_command *)&__ZL20proxy_luma_quant_tbl;
    psVar101 = (segment_command *)0x0;
    psVar59 = (segment_command *)0x0;
    psVar95 = psVar64;
    func_0x00fc1c48(psVar62,0);
    *(undefined4 *)((long)ppsVar32 + -0x188) = 0;
    *(undefined4 *)((long)ppsVar32 + -0x198) = 1;
    func_0x00f9f004(psVar62);
    if (0 < (int)psVar46) {
      uVar93 = (ulong)psVar46 & 0xffffffff;
      psVar101 = (segment_command *)(long)(int)psVar61;
      psVar46 = (segment_command *)((long)ppsVar32 + -0x300);
      psVar64 = (segment_command *)((long)&MACH_HEADER.magic + 1);
      psVar56 = auVar172._0_8_;
      do {
        *(segment_command **)((long)ppsVar32 + -0x470) = psVar56;
        psVar78 = (segment_command *)((long)&MACH_HEADER.magic + 1);
        iVar42 = func_0x00f9f0ac(psVar46,(undefined1 *)((long)ppsVar32 + -0x470));
        psVar61 = (segment_command *)((long)ppsVar32 + -0x470);
        if (iVar42 != 1) goto LAB_01535fbc;
        psVar56 = (segment_command *)(psVar101->segname + (long)(psVar56->segname + -0x10));
        uVar93 = uVar93 - 1;
        psVar61 = (segment_command *)((long)ppsVar32 + -0x470);
      } while (uVar93 != 0);
    }
    func_0x00fb2730((undefined1 *)((long)ppsVar32 + -0x300));
    psVar92 = (segment_command *)
              (ulong)(uint)(*(int *)(*(long *)((long)ppsVar32 + -0x2d8) + 0x30) -
                           *(int *)(*(long *)((long)ppsVar32 + -0x2d8) + 8));
  }
  func_0x00fb26dc((undefined1 *)((long)ppsVar32 + -0x300));
  if (*(long *)PTR____stack_chk_guard_01d15188 == *(long *)((long)ppsVar32 + -0x78)) {
    return psVar92;
  }
  psVar50 = (segment_command *)___stack_chk_fail();
  puVar35 = (undefined1 *)((long)ppsVar32 + -0x580);
  *(segment_command **)((long)ppsVar32 + -0x4a0) = param_6;
  *(segment_command **)((long)ppsVar32 + -0x498) = unaff_x27;
  *(segment_command **)((long)ppsVar32 + -0x490) = psVar46;
  *(segment_command **)((long)ppsVar32 + -0x488) = psVar92;
  *(undefined1 **)((long)ppsVar32 + -0x480) = (undefined1 *)((long)ppsVar32 + -0x10);
  *(undefined8 *)((long)ppsVar32 + -0x478) = 0x15360fc;
  puVar106 = (undefined1 *)((long)ppsVar32 + -0x480);
  *(undefined8 *)((long)ppsVar32 + -0x4a8) = *(undefined8 *)PTR____stack_chk_guard_01d15188;
  psVar46 = (segment_command *)((long)ppsVar32 + -0x570);
  (**(code **)(*(long *)psVar50 + 0x18))(psVar50,(undefined1 *)((long)ppsVar32 + -0x570));
  *(segment_command **)((long)ppsVar32 + -0x580) = psVar46;
  func_0x00574408("Fatal proxy error (%s)");
  uVar109 = 0x1536158;
  auVar173 = _longjmp(*(long *)psVar50 + 0xa8,1);
  param_5 = (char *)psVar56;
  unaff_x25 = psVar57;
  do {
    unaff_x22 = auVar173._8_8_;
    *(segment_command **)(puVar35 + -0x60) = param_6;
    *(segment_command **)(puVar35 + -0x58) = unaff_x27;
    *(segment_command **)(puVar35 + -0x50) = psVar62;
    *(segment_command **)(puVar35 + -0x48) = unaff_x25;
    *(char **)(puVar35 + -0x40) = param_5;
    *(segment_command **)(puVar35 + -0x38) = psVar101;
    *(segment_command **)(puVar35 + -0x30) = psVar64;
    *(segment_command **)(puVar35 + -0x28) = psVar61;
    *(segment_command **)(puVar35 + -0x20) = psVar46;
    *(segment_command **)(puVar35 + -0x18) = psVar50;
    *(undefined1 **)(puVar35 + -0x10) = puVar106;
    *(undefined8 *)(puVar35 + -8) = uVar109;
    *(undefined8 *)(puVar35 + -0x68) = *(undefined8 *)PTR____stack_chk_guard_01d15188;
    unaff_x25 = (segment_command *)(puVar35 + -0x460);
    psVar61 = psVar78;
    psVar46 = psVar95;
    psVar64 = psVar59;
    unaff_x23 = psVar45;
    puVar49 = (undefined8 *)func_0x00fc9cf0(unaff_x25);
    *(undefined8 **)(puVar35 + -0x2f8) = puVar49;
    *puVar49 = 0x15360fc;
    puVar49[2] = 0x1536334;
    iVar42 = _setjmp(puVar35 + -0x3b8);
    if (iVar42 == 1) goto LAB_015361d8;
    unaff_x25 = (segment_command *)(puVar35 + -0x2f8);
    func_0x00fc3460(unaff_x25,0x50,0x290);
    psVar61 = psVar45;
    func_0x00720ea8(unaff_x25,psVar59);
    iVar42 = func_0x00fc3598(unaff_x25,1);
    psVar57 = (segment_command *)0xffffffff;
    if ((((iVar42 == 1) && (*(int *)(puVar35 + -0x2c0) == 1)) &&
        (*(int *)(puVar35 + -0x2c8) == auVar173._8_4_)) &&
       (*(int *)(puVar35 + -0x2c4) == (int)psVar78)) {
      *(undefined4 *)(puVar35 + -0x298) = 0;
      func_0x00fa2bac(puVar35 + -0x2f8);
      if ((int)psVar78 < 1) {
LAB_015362d8:
        func_0x00fc38c0(puVar35 + -0x2f8);
        psVar57 = (segment_command *)0x0;
      }
      else {
        *(long *)(puVar35 + -0x468) = auVar173._0_8_;
        psVar61 = (segment_command *)((long)&MACH_HEADER.magic + 1);
        iVar42 = func_0x00fa2df0(puVar35 + -0x2f8,puVar35 + -0x468);
        if (iVar42 == 1) {
          unaff_x22 = (segment_command *)(long)(int)psVar95;
          psVar45 = (segment_command *)((ulong)psVar78 & 0xffffffff);
          psVar62 = (segment_command *)(unaff_x22->segname + auVar173._0_8_ + -8);
          psVar59 = (segment_command *)((long)&psVar45[-1].flags + 3);
          psVar78 = (segment_command *)(puVar35 + -0x468);
          psVar95 = (segment_command *)((long)&MACH_HEADER.magic + 1);
          unaff_x25 = (segment_command *)0x0;
          do {
            if (psVar59 == unaff_x25) goto LAB_015362d8;
            *(segment_command **)(puVar35 + -0x468) = psVar62;
            psVar61 = (segment_command *)((long)&MACH_HEADER.magic + 1);
            iVar42 = func_0x00fa2df0(puVar35 + -0x2f8,psVar78);
            psVar62 = (segment_command *)(unaff_x22->segname + (long)(psVar62->segname + -0x10));
            unaff_x25 = (segment_command *)((long)&unaff_x25->cmd + 1);
          } while (iVar42 == 1);
          if (psVar45 <= unaff_x25) goto LAB_015362d8;
        }
LAB_015361d8:
        psVar57 = (segment_command *)0xffffffff;
      }
    }
    func_0x00fb26dc(puVar35 + -0x2f8);
    if (*(long *)PTR____stack_chk_guard_01d15188 == *(long *)(puVar35 + -0x68)) {
      return psVar57;
    }
    plVar51 = (long *)___stack_chk_fail();
    pdVar33 = (double *)(puVar35 + -0x570);
    *(segment_command **)(puVar35 + -0x490) = psVar78;
    *(segment_command **)(puVar35 + -0x488) = psVar57;
    *(undefined1 **)(puVar35 + -0x480) = puVar35 + -0x10;
    *(undefined8 *)(puVar35 + -0x478) = 0x1536334;
    puVar106 = puVar35 + -0x480;
    *(undefined8 *)(puVar35 + -0x498) = *(undefined8 *)PTR____stack_chk_guard_01d15188;
    pcVar63 = puVar35 + -0x560;
    (**(code **)(*plVar51 + 0x18))(plVar51,puVar35 + -0x560);
    *(char **)(puVar35 + -0x570) = pcVar63;
    psVar57 = (segment_command *)func_0x00574408("Fatal proxy error (%s)");
    if (*(long *)PTR____stack_chk_guard_01d15188 == *(long *)(puVar35 + -0x498)) {
      return psVar57;
    }
    uVar109 = 0x15363a4;
    auVar171 = ___stack_chk_fail();
    auVar7 = auVar171._0_12_;
__ZN5Proxy13tjpg_compressEPhiiiiPvi:
    *(undefined8 *)((long)pdVar33 + -0x80) = unaff_d11;
    *(ulong *)((long)pdVar33 + -0x78) = unaff_d10;
    *(ulong *)((long)pdVar33 + -0x70) = unaff_d9;
    *(ulong *)((long)pdVar33 + -0x68) = unaff_d8;
    *(segment_command **)((long)pdVar33 + -0x60) = param_6;
    *(segment_command **)((long)pdVar33 + -0x58) = unaff_x27;
    *(segment_command **)((long)pdVar33 + -0x50) = psVar62;
    *(segment_command **)((long)pdVar33 + -0x48) = unaff_x25;
    *(segment_command **)((long)pdVar33 + -0x40) = psVar59;
    *(segment_command **)((long)pdVar33 + -0x38) = psVar45;
    *(segment_command **)((long)pdVar33 + -0x30) = unaff_x22;
    *(segment_command **)((long)pdVar33 + -0x28) = psVar95;
    *(segment_command **)((long)pdVar33 + -0x20) = psVar78;
    *(char **)((long)pdVar33 + -0x18) = pcVar63;
    *(undefined1 **)((long)pdVar33 + -0x10) = puVar106;
    *(undefined8 *)((long)pdVar33 + -8) = uVar109;
    ppuVar107 = (undefined1 **)((long)pdVar33 + -0x10);
    ppsVar32 = (segment_command **)((long)pdVar33 + -0x210);
    *(int *)((long)pdVar33 + -0x1ec) = (int)psVar46;
    *(long *)((long)pdVar33 + -0x1f8) = auVar7._0_8_;
    uVar69 = 0;
    iVar42 = 0;
    iVar68 = auVar7._8_4_;
    uVar110 = iVar68 / 0x1f0;
    uVar65 = (int)psVar61 / 0x1f0;
    if ((int)uVar110 < 2) {
      uVar110 = 1;
    }
    if (3 < uVar110) {
      uVar110 = 4;
    }
    if ((int)uVar65 < 2) {
      uVar65 = 1;
    }
    *(int *)((long)pdVar33 + -0x1f0) = iVar68;
    *(uint *)((long)pdVar33 + -0x1e0) = uVar110;
    *(int *)((long)pdVar33 + -0x1dc) = (int)psVar61;
    iVar94 = 0;
    if (uVar110 != 0) {
      iVar94 = iVar68 / (int)uVar110;
    }
    uVar110 = iVar94 + 7;
    uVar93 = (ulong)uVar110;
    *(undefined8 *)((long)pdVar33 + -0x90) = *(undefined8 *)PTR____stack_chk_guard_01d15188;
    *(segment_command **)((long)pdVar33 + -0x1e8) = psVar64;
    iVar68 = (int)psVar64;
    psVar59 = unaff_x23;
    psVar45 = param_7;
    do {
      uVar97 = 0;
      do {
        if ((int)uVar97 == 0 && (int)uVar69 == 0) {
          iVar42 = iVar42 + 0xe;
        }
        else {
          auVar171 = SEXT816((long)((ulong)*(uint *)(&__ZL20proxy_luma_quant_tbl +
                                                    (uVar97 + uVar69 * 8) * 4) * (long)iVar68 + 0x32
                                   )) * ZEXT816(0xa3d70a3d70a3d70b);
          iVar94 = (int)(auVar171._8_8_ >> 6) - (auVar171._12_4_ >> 0x1f);
          if (0x7ffe < iVar94) {
            iVar94 = 0x7fff;
          }
          if (iVar94 < 2) {
            iVar94 = 1;
          }
          iVar114 = 0;
          if (iVar94 != 0) {
            iVar114 = *(int *)(&__ZZN5Proxy17jpeg_compress_capEiiiE5range +
                              (uVar69 & 3 | (uVar97 & 3) << 2) * 4) / iVar94;
          }
          psVar59 = (segment_command *)((long)&MACH_HEADER.magic + 1);
          do {
            iVar42 = iVar42 + 1;
            uVar66 = (uint)psVar59;
            uVar43 = 1 << (ulong)(uVar66 & 0x1f);
            psVar45 = (segment_command *)(ulong)uVar43;
            psVar59 = (segment_command *)(ulong)(uVar66 + 1);
          } while ((int)uVar43 < iVar114);
          uVar43 = 1;
          do {
            uVar79 = 1 << (ulong)(uVar43 & 0x1f);
            psVar64 = (segment_command *)(ulong)uVar79;
            uVar43 = uVar43 + 1;
            iVar42 = iVar42 + 1;
          } while ((int)uVar79 < (int)uVar66);
        }
        uVar97 = uVar97 + 1;
      } while (uVar97 != 8);
      uVar69 = uVar69 + 1;
    } while (uVar69 != 8);
    if (3 < uVar65) {
      uVar65 = 4;
    }
    iVar68 = 0;
    if (uVar65 != 0) {
      iVar68 = *(int *)((long)pdVar33 + -0x1dc) / (int)uVar65;
    }
    uVar43 = iVar68 + 7;
    unaff_x21 = (segment_command *)(ulong)uVar43;
    param_5 = (char *)(ulong)(uVar65 * *(int *)((long)pdVar33 + -0x1e0));
    uVar79 = uVar110 | 7;
    uVar66 = uVar79 + 7;
    if (-1 < (int)uVar79) {
      uVar66 = uVar79;
    }
    uVar87 = uVar43 | 7;
    uVar79 = uVar87 + 7;
    if (-1 < (int)uVar87) {
      uVar79 = uVar87;
    }
    uVar79 = ((int)uVar79 >> 3) * ((int)uVar66 >> 3) * iVar42;
    uVar66 = uVar79 + 7;
    if (-1 < (int)uVar79) {
      uVar66 = uVar79;
    }
    iVar42 = (uVar66 & 0xfffffff8) + ((int)uVar66 >> 3);
    iVar68 = iVar42 + 7;
    if (-1 < iVar42) {
      iVar68 = iVar42;
    }
    uVar66 = ((int)uVar66 >> 3) + (iVar68 >> 3) + 0x800;
    psVar101 = (segment_command *)(ulong)uVar66;
    psVar57 = (segment_command *)
              _malloc((long)(int)(uVar66 * uVar65 * *(int *)((long)pdVar33 + -0x1e0)));
    unaff_x27 = psVar101;
    if (psVar57 != (segment_command *)0x0) break;
    unaff_x22 = (segment_command *)0xffffffff;
    if (*(long *)PTR____stack_chk_guard_01d15188 == *(long *)((long)pdVar33 + -0x90)) {
      return (segment_command *)0xffffffff;
    }
    uVar109 = 0x1537114;
    auVar174 = ___stack_chk_fail();
    ppsVar34 = (segment_command **)((long)pdVar33 + -0x210);
    param_7 = psVar45;
__ZN5Proxy13tjpg_plan_addEP22tjpg_plan_decompress_tPhiiiPKvi:
    auVar10._8_8_ = psVar62;
    auVar10._0_8_ = uVar93;
    psVar50 = auVar174._0_8_;
    ppsVar36 = (segment_command **)((long)ppsVar34 + -0x1c0);
    *(segment_command **)((long)ppsVar34 + -0x60) = param_6;
    *(segment_command **)((long)ppsVar34 + -0x58) = unaff_x27;
    *(segment_command **)((long)ppsVar34 + -0x50) = psVar62;
    *(segment_command **)((long)ppsVar34 + -0x48) = unaff_x25;
    *(char **)((long)ppsVar34 + -0x40) = param_5;
    *(segment_command **)((long)ppsVar34 + -0x38) = unaff_x23;
    *(segment_command **)((long)ppsVar34 + -0x30) = unaff_x22;
    *(segment_command **)((long)ppsVar34 + -0x28) = unaff_x21;
    *(segment_command **)((long)ppsVar34 + -0x20) = psVar78;
    *(ulong *)((long)ppsVar34 + -0x18) = uVar93;
    *(undefined1 ***)((long)ppsVar34 + -0x10) = ppuVar107;
    *(undefined8 *)((long)ppsVar34 + -8) = uVar109;
    ppuVar107 = (undefined1 **)((long)ppsVar34 + -0x10);
    *(undefined8 *)((long)ppsVar34 + -0x70) = *(undefined8 *)PTR____stack_chk_guard_01d15188;
    psVar62 = psVar50;
    if (-1 < (int)psVar50->cmd) {
      param_5 = (char *)0x0;
      unaff_x23 = (segment_command *)0x0;
      do {
        pcVar63 = ((segment_command *)param_5)->segname;
        uVar110 = (byte)pcVar63[(long)((long)psVar59->segname + -0x10)] & 0x7f | (int)unaff_x23 << 7
        ;
        unaff_x23 = (segment_command *)(ulong)uVar110;
        param_5 = (char *)((long)&((segment_command *)param_5)->cmd + 1);
      } while (pcVar63[(long)((long)psVar59->segname + -0x10)] < '\0');
      psVar78 = psVar59;
      unaff_x25 = psVar64;
      auVar10 = auVar174;
      if (uVar110 - 0x11 < 0xfffffff0) {
        psVar62 = (segment_command *)func_0x00574408("tjpg_plan_add: bad tile specification.");
        psVar50->cmd = 0xffffffff;
      }
      else {
        psVar45 = (segment_command *)0x0;
        do {
          lVar100 = 0;
          uVar65 = 0;
          iVar42 = (int)param_5;
          uVar43 = iVar42 + 4;
          do {
            uVar66 = uVar43;
            bVar1 = *(byte *)((long)psVar59->segname + lVar100 + iVar42 + -8);
            uVar65 = bVar1 & 0x7f | uVar65 << 7;
            lVar100 = lVar100 + 1;
            uVar43 = uVar66 + 1;
          } while ((char)bVar1 < '\0');
          lVar81 = 0;
          uVar43 = 0;
          *(uint *)((long)ppsVar34 + (long)psVar45 * 4 + -0xb0) = uVar65;
          lVar100 = (long)iVar42 + (long)(int)lVar100;
          do {
            uVar65 = uVar66;
            bVar1 = *(byte *)((long)psVar59->segname + lVar81 + lVar100 + -8);
            uVar43 = bVar1 & 0x7f | uVar43 << 7;
            lVar81 = lVar81 + 1;
            uVar66 = uVar65 + 1;
          } while ((char)bVar1 < '\0');
          lVar88 = 0;
          uVar66 = 0;
          *(uint *)((long)ppsVar34 + (long)psVar45 * 4 + -0xf0) = uVar43;
          iVar42 = (int)lVar100 + (int)lVar81;
          do {
            uVar43 = uVar65;
            bVar1 = *(byte *)((long)psVar59->segname + lVar88 + iVar42 + -8);
            uVar66 = bVar1 & 0x7f | uVar66 << 7;
            lVar88 = lVar88 + 1;
            uVar65 = uVar43 + 1;
          } while ((char)bVar1 < '\0');
          lVar100 = 0;
          psVar62 = (segment_command *)0x0;
          *(uint *)((long)ppsVar34 + (long)psVar45 * 4 + -0x130) = uVar66;
          do {
            uVar65 = uVar43;
            param_5 = (char *)(ulong)uVar65;
            bVar1 = *(byte *)((long)psVar59->segname + lVar100 + (iVar42 + (int)lVar88) + -8);
            uVar66 = bVar1 & 0x7f | (int)psVar62 << 7;
            psVar62 = (segment_command *)(ulong)uVar66;
            lVar100 = lVar100 + 1;
            uVar43 = uVar65 + 1;
          } while ((char)bVar1 < '\0');
          uVar43 = 0;
          *(uint *)((long)ppsVar34 + (long)psVar45 * 4 + -0x170) = uVar66;
          pbVar86 = (byte *)((long)psVar59->segname + (long)(int)uVar65 + -8);
          do {
            bVar1 = *pbVar86;
            uVar43 = bVar1 & 0x7f | uVar43 << 7;
            param_5 = (char *)(ulong)((int)param_5 + 1);
            pbVar86 = pbVar86 + 1;
          } while ((char)bVar1 < '\0');
          *(uint *)((long)ppsVar34 + (long)psVar45 * 4 + -0x1b0) = uVar43;
          psVar45 = (segment_command *)((long)&psVar45->cmd + 1);
        } while (psVar45 != unaff_x23);
        if (uVar110 != 0) {
          *(segment_command **)((long)ppsVar34 + -0x1c0) = psVar50;
          puVar82 = (undefined4 *)((long)ppsVar34 + -0x170);
          piVar74 = (int *)((long)ppsVar34 + -0xf0);
          puVar71 = (uint *)((long)ppsVar34 + -0xb0);
          puVar102 = (uint *)((long)ppsVar34 + -0x1b0);
          puVar105 = (undefined4 *)((long)ppsVar34 + -0x130);
          do {
            lVar100 = (long)(int)psVar50->cmdsize;
            psVar50->cmdsize = psVar50->cmdsize + 1;
            *(long *)(psVar50->segname + lVar100 * 8 + 8) =
                 (long)psVar59->segname + (long)(int)param_5 + -8;
            unaff_x27 = (segment_command *)(puVar102 + 1);
            uVar110 = *puVar102;
            unaff_x21 = (segment_command *)(ulong)uVar110;
            *(uint *)(psVar50[5].segname + lVar100 * 4 + 0x20) = uVar110;
            unaff_x22 = (segment_command *)(puVar71 + 1);
            *(ulong *)(psVar50[2].segname + lVar100 * 8 + -8) =
                 auVar174._8_8_ + (ulong)(uint)(*piVar74 * (int)psVar64) + (ulong)*puVar71;
            *(int *)(psVar50[6].segname + lVar100 * 4 + 0x18) = (int)psVar64;
            param_6 = (segment_command *)(puVar105 + 1);
            *(undefined4 *)(psVar50[3].segname + lVar100 * 4 + 0x30) = *puVar105;
            auVar10._8_8_ = auVar174._8_8_;
            auVar10._0_8_ = puVar82 + 1;
            *(undefined4 *)(psVar50[4].segname + lVar100 * 4 + 0x28) = *puVar82;
            if (0xf < (int)psVar50->cmdsize) {
              *(int **)((long)ppsVar34 + -0x1b8) = piVar74 + 1;
              uVar109 = 0x1537354;
              goto __ZN5Proxy13tjpg_plan_runEP22tjpg_plan_decompress_t;
            }
            param_5 = (char *)(ulong)(uVar110 + (int)param_5);
            unaff_x23 = (segment_command *)((long)&unaff_x23[-1].flags + 3);
            puVar82 = puVar82 + 1;
            piVar74 = piVar74 + 1;
            puVar71 = (uint *)unaff_x22;
            puVar102 = (uint *)unaff_x27;
            puVar105 = (undefined4 *)param_6;
            auVar10 = auVar174;
          } while (unaff_x23 != (segment_command *)0x0);
        }
      }
    }
    if (*(long *)PTR____stack_chk_guard_01d15188 == *(long *)((long)ppsVar34 + -0x70)) {
      return psVar62;
    }
    uVar109 = 0x15373a0;
    psVar50 = (segment_command *)___stack_chk_fail();
    ppsVar36 = (segment_command **)((long)ppsVar34 + -0x1c0);
__ZN5Proxy13tjpg_plan_runEP22tjpg_plan_decompress_t:
    psVar62 = auVar10._8_8_;
    puVar35 = (undefined1 *)((long)ppsVar36 + -0x110);
    *(segment_command **)((long)ppsVar36 + -0x60) = param_6;
    *(segment_command **)((long)ppsVar36 + -0x58) = unaff_x27;
    *(segment_command **)((long)ppsVar36 + -0x50) = psVar62;
    *(segment_command **)((long)ppsVar36 + -0x48) = unaff_x25;
    *(char **)((long)ppsVar36 + -0x40) = param_5;
    *(segment_command **)((long)ppsVar36 + -0x38) = unaff_x23;
    *(segment_command **)((long)ppsVar36 + -0x30) = unaff_x22;
    *(segment_command **)((long)ppsVar36 + -0x28) = unaff_x21;
    *(segment_command **)((long)ppsVar36 + -0x20) = psVar78;
    *(long *)((long)ppsVar36 + -0x18) = auVar10._0_8_;
    *(undefined1 ***)((long)ppsVar36 + -0x10) = ppuVar107;
    *(undefined8 *)((long)ppsVar36 + -8) = uVar109;
    puVar106 = (undefined1 *)((long)ppsVar36 + -0x10);
    *(undefined8 *)((long)ppsVar36 + -0x70) = *(undefined8 *)PTR____stack_chk_guard_01d15188;
    psVar59 = (segment_command *)(ulong)psVar50->cmd;
    if ((int)psVar50->cmd < 0) goto LAB_0153773c;
    uVar110 = psVar50->cmdsize;
    psVar101 = (segment_command *)(ulong)uVar110;
    if ((int)uVar110 < 1) {
      psVar59 = (segment_command *)0x0;
      goto LAB_0153773c;
    }
    if ((__DEBUG_PROXY_THREADSIZE < 1 || uVar110 == 1) || psVar50->segname[0] == '\0') {
      *(undefined1 *)((long)ppsVar36 + -0xe1) = 0;
    }
    else {
      lVar100 = 0;
      iVar42 = 0;
      do {
        if ((__DEBUG_PROXY_THREADSIZE <= *(int *)(psVar50[3].segname + lVar100 + 0x30)) ||
           (__DEBUG_PROXY_THREADSIZE <= *(int *)(psVar50[4].segname + lVar100 + 0x28))) {
          iVar42 = iVar42 + 1;
        }
        lVar100 = lVar100 + 4;
      } while ((long)psVar101 * 4 - lVar100 != 0);
      *(undefined1 *)((long)ppsVar36 + -0xe1) = 0;
      if (1 < iVar42) {
        *(undefined1 **)((long)ppsVar36 + -0xf8) = (undefined1 *)((long)ppsVar36 + -0xe1);
        *(segment_command **)((long)ppsVar36 + -0xf0) = psVar50;
        *(undefined8 *)((long)ppsVar36 + -0xc0) = 0x32aaaba7;
        *(undefined8 *)((long)ppsVar36 + -0xb0) = 0;
        *(undefined8 *)((long)ppsVar36 + -0xb8) = 0;
        *(undefined8 *)((long)ppsVar36 + -0xa0) = 0;
        *(undefined8 *)((long)ppsVar36 + -0xa8) = 0;
        *(undefined8 *)((long)ppsVar36 + -0x90) = 0;
        *(undefined8 *)((long)ppsVar36 + -0x98) = 0;
        *(undefined8 *)((long)ppsVar36 + -0x80) = 0;
        *(undefined8 *)((long)ppsVar36 + -0x88) = 0;
        *(undefined1 *)((long)ppsVar36 + -0x78) = 0;
        uVar43 = __ZNSt3__16thread20hardware_concurrencyEv();
        uVar65 = uVar43;
        if (uVar110 <= uVar43) {
          uVar65 = uVar110;
        }
        *(undefined8 *)((long)ppsVar36 + -0xe0) = 0;
        *(undefined8 *)((long)ppsVar36 + -0xd8) = 0;
        *(undefined8 *)((long)ppsVar36 + -0xd0) = 0;
        func_0x0019952c((undefined1 *)((long)ppsVar36 + -0xe0),uVar65);
        if (uVar65 == 0) goto LAB_01537774;
        uVar66 = 0;
        uVar79 = 0;
        if (uVar43 != 0) {
          uVar79 = uVar110 / uVar43;
        }
        *(uint *)((long)ppsVar36 + -0xfc) = uVar79;
        *(uint *)((long)ppsVar36 + -0x100) = uVar110 - uVar79 * uVar43;
        plVar51 = *(long **)((long)ppsVar36 + -0xd8);
        goto LAB_01537534;
      }
    }
    psVar46 = psVar50 + 2;
    psVar61 = (segment_command *)&psVar50[6].vmsize;
    psVar59 = *(segment_command **)(psVar50->segname + 8);
    psVar45 = (segment_command *)(ulong)(uint)psVar50[5].fileoff;
    uVar44 = psVar46->cmd;
    uVar55 = psVar46->cmdsize;
    auVar173._4_4_ = uVar55;
    auVar173._0_4_ = uVar44;
    psVar95 = (segment_command *)(ulong)(uint)*(qword *)psVar61;
    auVar173._8_4_ = psVar50[3].maxprot;
    auVar173._12_4_ = 0;
    psVar78 = (segment_command *)(ulong)(uint)psVar50[4].filesize;
    uVar109 = 0x15376f0;
    psVar64 = unaff_x22;
  } while( true );
  *(segment_command **)((long)pdVar33 + -0x210) = unaff_x23;
  *(int *)((long)pdVar33 + -0x204) = (int)param_7;
  psVar59 = (segment_command *)0x0;
  uVar110 = uVar110 & 0xfffffff8;
  unaff_x22 = (segment_command *)(ulong)uVar110;
  uVar43 = uVar43 & 0xfffffff8;
  unaff_x23 = (segment_command *)(ulong)uVar43;
  *(long *)((long)pdVar33 + -0x1d8) = (long)(int)uVar66;
  *(segment_command **)((long)pdVar33 + -0x200) = psVar57;
  plVar51 = (long *)0x0;
  psVar62 = (segment_command *)0x0;
  psVar61 = (segment_command *)(ulong)*(uint *)((long)pdVar33 + -0x1ec);
  if ((int)*(uint *)((long)pdVar33 + -0x1f0) <= (int)uVar110) {
    uVar110 = *(uint *)((long)pdVar33 + -0x1f0);
  }
  if ((int)*(uint *)((long)pdVar33 + -0x1dc) <= (int)uVar43) {
    uVar43 = *(uint *)((long)pdVar33 + -0x1dc);
  }
  uVar93 = (ulong)uVar110;
  auVar172._8_4_ = uVar110;
  auVar172._0_8_ = *(undefined8 *)((long)pdVar33 + -0x1f8);
  auVar172._12_4_ = 0;
  psVar46 = (segment_command *)(ulong)uVar43;
  psVar64 = *(segment_command **)((long)pdVar33 + -0x1e8);
  uVar109 = 0x1536654;
  unaff_x21 = psVar46;
  param_6 = psVar57;
  goto __ZN5Proxy13jpeg_compressEPhiiiiPvi;
code_r0x015376a8:
  if (plVar53 != (long *)0x0) {
    lVar100 = 5;
LAB_01537680:
    (**(code **)(*plVar53 + lVar100 * 8))();
  }
  goto joined_r0x01537670;
LAB_01537534:
  do {
    if (plVar51 < *(long **)((long)ppsVar36 + -0xd0)) {
      plVar51[3] = 0;
      puVar49 = (undefined8 *)__Znwm(0x30);
      *puVar49 = &
                 PTR___ZNSt3__110__function6__funcIZN2P18Parallel7Details9ForStaticIiZN5Proxy13tjpg_plan_runEP22tjpg_plan_decompress_tE3__0EEvT_SA_DTmifL0pK0_fL0pK_ERKT0_EUliE_NS_9allocatorISF_EEFviEED1Ev_01ffcf68
      ;
      puVar49[1] = (undefined1 *)((long)ppsVar36 + -0xc0);
      puVar49[2] = (undefined1 *)((long)ppsVar36 + -0xf8);
      uVar70 = *(undefined4 *)((long)ppsVar36 + -0x100);
      *(uint *)(puVar49 + 3) = uVar66;
      *(undefined4 *)((long)puVar49 + 0x1c) = uVar70;
      *(undefined4 *)(puVar49 + 4) = 0;
      *(uint *)((long)puVar49 + 0x24) = uVar110;
      uVar70 = *(undefined4 *)((long)ppsVar36 + -0xfc);
      *(undefined4 *)(puVar49 + 5) = 1;
      *(undefined4 *)((long)puVar49 + 0x2c) = uVar70;
      plVar54 = plVar51 + 4;
      plVar51[3] = (long)puVar49;
    }
    else {
      plVar103 = *(long **)((long)ppsVar36 + -0xe0);
      lVar100 = (long)plVar51 - (long)plVar103 >> 5;
      uVar93 = lVar100 + 1;
      if (uVar93 >> 0x3b != 0) goto LAB_01537818;
      uVar97 = (long)*(long **)((long)ppsVar36 + -0xd0) - (long)plVar103;
      uVar69 = (long)uVar97 >> 4;
      if (uVar69 <= uVar93) {
        uVar69 = uVar93;
      }
      if (0x7fffffffffffffdf < uVar97) {
        uVar69 = 0x7ffffffffffffff;
      }
      if (uVar69 == 0) {
        lVar81 = 0;
      }
      else {
        if (uVar69 >> 0x3b != 0) {
          func_0x00108f70();
          goto LAB_0153784c;
        }
        lVar81 = __Znwm(uVar69 << 5);
      }
      lVar100 = lVar81 + lVar100 * 0x20;
      *(undefined8 *)(lVar100 + 0x18) = 0;
      puVar49 = (undefined8 *)__Znwm(0x30);
      *puVar49 = &
                 PTR___ZNSt3__110__function6__funcIZN2P18Parallel7Details9ForStaticIiZN5Proxy13tjpg_plan_runEP22tjpg_plan_decompress_tE3__0EEvT_SA_DTmifL0pK0_fL0pK_ERKT0_EUliE_NS_9allocatorISF_EEFviEED1Ev_01ffcf68
      ;
      puVar49[1] = (undefined1 *)((long)ppsVar36 + -0xc0);
      lVar81 = lVar81 + uVar69 * 0x20;
      puVar49[2] = (undefined1 *)((long)ppsVar36 + -0xf8);
      uVar70 = *(undefined4 *)((long)ppsVar36 + -0x100);
      *(uint *)(puVar49 + 3) = uVar66;
      *(undefined4 *)((long)puVar49 + 0x1c) = uVar70;
      *(undefined4 *)(puVar49 + 4) = 0;
      *(uint *)((long)puVar49 + 0x24) = uVar110;
      uVar70 = *(undefined4 *)((long)ppsVar36 + -0xfc);
      *(undefined4 *)(puVar49 + 5) = 1;
      *(undefined4 *)((long)puVar49 + 0x2c) = uVar70;
      plVar54 = (long *)(lVar100 + 0x20);
      *(undefined8 **)(lVar100 + 0x18) = puVar49;
      if (plVar51 == plVar103) {
        *(long *)((long)ppsVar36 + -0xe0) = lVar100;
        *(long **)((long)ppsVar36 + -0xd8) = plVar54;
        *(long *)((long)ppsVar36 + -0xd0) = lVar81;
      }
      else {
        *(long *)((long)ppsVar36 + -0x108) = lVar81;
        lVar81 = 0;
        plVar53 = plVar51;
        do {
          plVar96 = (long *)(lVar100 + lVar81);
          plVar72 = *(long **)((long)plVar51 + lVar81 + -8);
          if (plVar72 == (long *)0x0) {
LAB_01537600:
            plVar96[-1] = 0;
          }
          else {
            plVar52 = (long *)((long)plVar51 + lVar81 + -0x20);
            if (plVar52 != plVar72) {
              plVar96[-1] = (long)plVar72;
              plVar96 = plVar53;
              goto LAB_01537600;
            }
            plVar96[-1] = (long)(plVar96 + -4);
            (**(code **)(*plVar52 + 0x18))();
          }
          plVar53 = plVar53 + -4;
          lVar81 = lVar81 + -0x20;
        } while ((long *)((long)plVar51 + lVar81) != plVar103);
        plVar51 = *(long **)((long)ppsVar36 + -0xe0);
        plVar103 = *(long **)((long)ppsVar36 + -0xd8);
        *(long *)((long)ppsVar36 + -0xe0) = lVar100 + lVar81;
        *(long **)((long)ppsVar36 + -0xd8) = plVar54;
        *(undefined8 *)((long)ppsVar36 + -0xd0) = *(undefined8 *)((long)ppsVar36 + -0x108);
joined_r0x01537670:
        if (plVar103 != plVar51) {
          plVar96 = plVar103 + -4;
          plVar53 = (long *)plVar103[-1];
          plVar103 = plVar96;
          if (plVar96 != plVar53) goto code_r0x015376a8;
          lVar100 = 4;
          plVar53 = plVar96;
          goto LAB_01537680;
        }
      }
      if (plVar51 != (long *)0x0) {
        __ZdlPv(plVar51);
      }
    }
    *(long **)((long)ppsVar36 + -0xd8) = plVar54;
    uVar66 = uVar66 + 1;
    plVar51 = plVar54;
  } while (uVar65 != uVar66);
LAB_01537774:
  func_0x00728824((undefined1 *)((long)ppsVar36 + -0xe0));
  if ((*(byte *)((long)ppsVar36 + -0x78) & 1) == 0) {
    plVar51 = *(long **)((long)ppsVar36 + -0xe0);
    if (plVar51 != (long *)0x0) {
      plVar54 = plVar51;
      plVar103 = *(long **)((long)ppsVar36 + -0xd8);
      if (*(long **)((long)ppsVar36 + -0xd8) != plVar51) {
        do {
          plVar53 = plVar103 + -4;
          plVar54 = (long *)plVar103[-1];
          if (plVar53 == plVar54) {
            lVar100 = 4;
            plVar54 = plVar53;
LAB_015377b0:
            (**(code **)(*plVar54 + lVar100 * 8))();
          }
          else if (plVar54 != (long *)0x0) {
            lVar100 = 5;
            goto LAB_015377b0;
          }
          plVar103 = plVar53;
        } while (plVar53 != plVar51);
        plVar54 = *(long **)((long)ppsVar36 + -0xe0);
      }
      *(long **)((long)ppsVar36 + -0xd8) = plVar51;
      __ZdlPv(plVar54);
    }
    __ZNSt13exception_ptrD1Ev((undefined1 *)((long)ppsVar36 + -0x80));
    __ZNSt3__15mutexD1Ev((undefined1 *)((long)ppsVar36 + -0xc0));
    if ((*(byte *)((long)ppsVar36 + -0xe1) & 1) == 0) {
      psVar59 = (segment_command *)0x0;
      psVar50->cmdsize = 0;
    }
    else {
      psVar59 = (segment_command *)0xffffffff;
      psVar50->cmd = 0xffffffff;
    }
LAB_0153773c:
    if (*(long *)PTR____stack_chk_guard_01d15188 == *(long *)((long)ppsVar36 + -0x70)) {
      return psVar59;
    }
    ___stack_chk_fail(psVar59);
LAB_01537818:
    func_0x00108ee8((undefined1 *)((long)ppsVar36 + -0xe0));
  }
  else {
    __ZNSt3__15mutex4lockEv((undefined1 *)((long)ppsVar36 + -0xc0));
    __ZNSt13exception_ptrC1ERKS_
              ((undefined1 *)((long)ppsVar36 + -200),(undefined1 *)((long)ppsVar36 + -0x80));
    __ZSt17rethrow_exceptionSt13exception_ptr((undefined1 *)((long)ppsVar36 + -200));
  }
LAB_0153784c:
                    /* WARNING: Does not return */
  pcVar31 = (code *)SoftwareBreakpoint(1,0x1537850);
  (*pcVar31)();
}


/* __ZN5Proxy14LoadSturdyJPEGERNSt3__114basic_ifstreamIcNS0_11char_traitsIcEEEER12CImageBufferiiib @ 01534768 */

/* WARNING: Possible PIC construction at 0x01536650: Changing call to branch */
/* WARNING: Possible PIC construction at 0x015376ec: Changing call to branch */
/* WARNING: Possible PIC construction at 0x01537350: Changing call to branch */
/* WARNING: Possible PIC construction at 0x01534f18: Changing call to branch */
/* WARNING: Possible PIC construction at 0x01534f6c: Changing call to branch */
/* WARNING: Possible PIC construction at 0x01534fa4: Changing call to branch */
/* WARNING: Removing unreachable block (ram,0x01537354) */
/* WARNING: Removing unreachable block (ram,0x01537360) */
/* WARNING: Removing unreachable block (ram,0x015376f0) */
/* WARNING: Removing unreachable block (ram,0x0153771c) */
/* WARNING: Removing unreachable block (ram,0x015376f4) */
/* WARNING: Removing unreachable block (ram,0x01537704) */
/* WARNING: Removing unreachable block (ram,0x01536654) */
/* WARNING: Removing unreachable block (ram,0x01537078) */
/* WARNING: Removing unreachable block (ram,0x01536658) */
/* WARNING: Removing unreachable block (ram,0x0153669c) */
/* WARNING: Removing unreachable block (ram,0x01536720) */
/* WARNING: Removing unreachable block (ram,0x01536758) */
/* WARNING: Removing unreachable block (ram,0x01536794) */
/* WARNING: Removing unreachable block (ram,0x01536854) */
/* WARNING: Removing unreachable block (ram,0x01536860) */
/* WARNING: Removing unreachable block (ram,0x0153687c) */
/* WARNING: Removing unreachable block (ram,0x015368cc) */
/* WARNING: Removing unreachable block (ram,0x015368fc) */
/* WARNING: Removing unreachable block (ram,0x0153697c) */
/* WARNING: Removing unreachable block (ram,0x01536984) */
/* WARNING: Removing unreachable block (ram,0x01536884) */
/* WARNING: Removing unreachable block (ram,0x0153698c) */
/* WARNING: Removing unreachable block (ram,0x01536994) */
/* WARNING: Removing unreachable block (ram,0x015369b4) */
/* WARNING: Removing unreachable block (ram,0x015369b8) */
/* WARNING: Removing unreachable block (ram,0x0153679c) */
/* WARNING: Removing unreachable block (ram,0x01536760) */
/* WARNING: Removing unreachable block (ram,0x01536790) */
/* WARNING: Removing unreachable block (ram,0x01536734) */
/* WARNING: Removing unreachable block (ram,0x015367d4) */
/* WARNING: Removing unreachable block (ram,0x01536810) */
/* WARNING: Removing unreachable block (ram,0x01536890) */
/* WARNING: Removing unreachable block (ram,0x0153689c) */
/* WARNING: Removing unreachable block (ram,0x015368b8) */
/* WARNING: Removing unreachable block (ram,0x01536a20) */
/* WARNING: Removing unreachable block (ram,0x01536a50) */
/* WARNING: Removing unreachable block (ram,0x01536ad0) */
/* WARNING: Removing unreachable block (ram,0x01536ad8) */
/* WARNING: Removing unreachable block (ram,0x015368c0) */
/* WARNING: Removing unreachable block (ram,0x01536ae0) */
/* WARNING: Removing unreachable block (ram,0x01536ae8) */
/* WARNING: Removing unreachable block (ram,0x01536b08) */
/* WARNING: Removing unreachable block (ram,0x01536b0c) */
/* WARNING: Removing unreachable block (ram,0x01536818) */
/* WARNING: Removing unreachable block (ram,0x01536850) */
/* WARNING: Removing unreachable block (ram,0x015367dc) */
/* WARNING: Removing unreachable block (ram,0x0153680c) */
/* WARNING: Removing unreachable block (ram,0x01536754) */
/* WARNING: Removing unreachable block (ram,0x015369dc) */
/* WARNING: Removing unreachable block (ram,0x01536b30) */
/* WARNING: Removing unreachable block (ram,0x01536b6c) */
/* WARNING: Removing unreachable block (ram,0x01536c2c) */
/* WARNING: Removing unreachable block (ram,0x01536c38) */
/* WARNING: Removing unreachable block (ram,0x01536c54) */
/* WARNING: Removing unreachable block (ram,0x01536ca4) */
/* WARNING: Removing unreachable block (ram,0x01536cd4) */
/* WARNING: Removing unreachable block (ram,0x01536d54) */
/* WARNING: Removing unreachable block (ram,0x01536d5c) */
/* WARNING: Removing unreachable block (ram,0x01536c5c) */
/* WARNING: Removing unreachable block (ram,0x01536d64) */
/* WARNING: Removing unreachable block (ram,0x01536d6c) */
/* WARNING: Removing unreachable block (ram,0x01536d8c) */
/* WARNING: Removing unreachable block (ram,0x01536d90) */
/* WARNING: Removing unreachable block (ram,0x01536b74) */
/* WARNING: Removing unreachable block (ram,0x01536b38) */
/* WARNING: Removing unreachable block (ram,0x01536b68) */
/* WARNING: Removing unreachable block (ram,0x015369fc) */
/* WARNING: Removing unreachable block (ram,0x01536bac) */
/* WARNING: Removing unreachable block (ram,0x01536be8) */
/* WARNING: Removing unreachable block (ram,0x01536c68) */
/* WARNING: Removing unreachable block (ram,0x01536c74) */
/* WARNING: Removing unreachable block (ram,0x01536c90) */
/* WARNING: Removing unreachable block (ram,0x01536dd8) */
/* WARNING: Removing unreachable block (ram,0x01536e08) */
/* WARNING: Removing unreachable block (ram,0x01536e88) */
/* WARNING: Removing unreachable block (ram,0x01536e90) */
/* WARNING: Removing unreachable block (ram,0x01536c98) */
/* WARNING: Removing unreachable block (ram,0x01536e98) */
/* WARNING: Removing unreachable block (ram,0x01536ea0) */
/* WARNING: Removing unreachable block (ram,0x01536ec0) */
/* WARNING: Removing unreachable block (ram,0x01536ec4) */
/* WARNING: Removing unreachable block (ram,0x01536bf0) */
/* WARNING: Removing unreachable block (ram,0x01536c28) */
/* WARNING: Removing unreachable block (ram,0x01536bb4) */
/* WARNING: Removing unreachable block (ram,0x01536be4) */
/* WARNING: Removing unreachable block (ram,0x01536a1c) */
/* WARNING: Removing unreachable block (ram,0x01536db4) */
/* WARNING: Removing unreachable block (ram,0x01536708) */
/* WARNING: Removing unreachable block (ram,0x01536dd4) */
/* WARNING: Removing unreachable block (ram,0x01536ee8) */
/* WARNING: Removing unreachable block (ram,0x01536f0c) */
/* WARNING: Removing unreachable block (ram,0x01536f38) */
/* WARNING: Removing unreachable block (ram,0x01536f44) */
/* WARNING: Removing unreachable block (ram,0x01536f60) */
/* WARNING: Removing unreachable block (ram,0x01536f74) */
/* WARNING: Removing unreachable block (ram,0x01536fa4) */
/* WARNING: Removing unreachable block (ram,0x01537024) */
/* WARNING: Removing unreachable block (ram,0x0153702c) */
/* WARNING: Removing unreachable block (ram,0x01536f68) */
/* WARNING: Removing unreachable block (ram,0x01537034) */
/* WARNING: Removing unreachable block (ram,0x0153703c) */
/* WARNING: Removing unreachable block (ram,0x0153705c) */
/* WARNING: Removing unreachable block (ram,0x01537060) */
/* WARNING: Removing unreachable block (ram,0x01536f14) */
/* WARNING: Removing unreachable block (ram,0x01536ef0) */
/* WARNING: Removing unreachable block (ram,0x01536710) */
/* WARNING: Removing unreachable block (ram,0x01537084) */
/* WARNING: Removing unreachable block (ram,0x0153708c) */
/* WARNING: Removing unreachable block (ram,0x015370c0) */
/* WARNING: Removing unreachable block (ram,0x0153709c) */
/* WARNING: Removing unreachable block (ram,0x015370bc) */
/* WARNING: Removing unreachable block (ram,0x015370c4) */
/* WARNING: Removing unreachable block (ram,0x01534fa8) */
/* WARNING: Removing unreachable block (ram,0x01535974) */
/* WARNING: Removing unreachable block (ram,0x01534fac) */
/* WARNING: Removing unreachable block (ram,0x01534fc4) */
/* WARNING: Removing unreachable block (ram,0x01534fd0) */
/* WARNING: Removing unreachable block (ram,0x01534fd8) */
/* WARNING: Removing unreachable block (ram,0x01534fe4) */
/* WARNING: Removing unreachable block (ram,0x01535008) */
/* WARNING: Removing unreachable block (ram,0x0153501c) */
/* WARNING: Removing unreachable block (ram,0x0153502c) */
/* WARNING: Removing unreachable block (ram,0x01534ff8) */
/* WARNING: Removing unreachable block (ram,0x01535030) */
/* WARNING: Removing unreachable block (ram,0x01535004) */
/* WARNING: Removing unreachable block (ram,0x0153504c) */
/* WARNING: Removing unreachable block (ram,0x01535064) */
/* WARNING: Removing unreachable block (ram,0x0153506c) */
/* WARNING: Removing unreachable block (ram,0x01535074) */
/* WARNING: Removing unreachable block (ram,0x01535080) */
/* WARNING: Removing unreachable block (ram,0x015350b0) */
/* WARNING: Removing unreachable block (ram,0x01535084) */
/* WARNING: Removing unreachable block (ram,0x015350d4) */
/* WARNING: Removing unreachable block (ram,0x0153508c) */
/* WARNING: Removing unreachable block (ram,0x015350f8) */
/* WARNING: Removing unreachable block (ram,0x01535094) */
/* WARNING: Removing unreachable block (ram,0x0153512c) */
/* WARNING: Removing unreachable block (ram,0x01535138) */
/* WARNING: Removing unreachable block (ram,0x015350ac) */
/* WARNING: Removing unreachable block (ram,0x01535150) */
/* WARNING: Removing unreachable block (ram,0x01535168) */
/* WARNING: Removing unreachable block (ram,0x0153517c) */
/* WARNING: Removing unreachable block (ram,0x01535188) */
/* WARNING: Removing unreachable block (ram,0x0153515c) */
/* WARNING: Removing unreachable block (ram,0x0153518c) */
/* WARNING: Removing unreachable block (ram,0x01535164) */
/* WARNING: Removing unreachable block (ram,0x015351a4) */
/* WARNING: Removing unreachable block (ram,0x015351b8) */
/* WARNING: Removing unreachable block (ram,0x015351c0) */
/* WARNING: Removing unreachable block (ram,0x01535874) */
/* WARNING: Removing unreachable block (ram,0x015351cc) */
/* WARNING: Removing unreachable block (ram,0x015351d8) */
/* WARNING: Removing unreachable block (ram,0x0153590c) */
/* WARNING: Removing unreachable block (ram,0x01535910) */
/* WARNING: Removing unreachable block (ram,0x0153591c) */
/* WARNING: Removing unreachable block (ram,0x01535928) */
/* WARNING: Removing unreachable block (ram,0x01535940) */
/* WARNING: Removing unreachable block (ram,0x01535954) */
/* WARNING: Removing unreachable block (ram,0x015351f8) */
/* WARNING: Removing unreachable block (ram,0x01535224) */
/* WARNING: Removing unreachable block (ram,0x01535958) */
/* WARNING: Removing unreachable block (ram,0x01535230) */
/* WARNING: Removing unreachable block (ram,0x0153523c) */
/* WARNING: Removing unreachable block (ram,0x01535254) */
/* WARNING: Removing unreachable block (ram,0x01535258) */
/* WARNING: Removing unreachable block (ram,0x0153527c) */
/* WARNING: Removing unreachable block (ram,0x015352a8) */
/* WARNING: Removing unreachable block (ram,0x015352ac) */
/* WARNING: Removing unreachable block (ram,0x015352c4) */
/* WARNING: Removing unreachable block (ram,0x015352d0) */
/* WARNING: Removing unreachable block (ram,0x015352d4) */
/* WARNING: Removing unreachable block (ram,0x015352dc) */
/* WARNING: Removing unreachable block (ram,0x01535288) */
/* WARNING: Removing unreachable block (ram,0x015352e0) */
/* WARNING: Removing unreachable block (ram,0x01535290) */
/* WARNING: Removing unreachable block (ram,0x015352ec) */
/* WARNING: Removing unreachable block (ram,0x015352a0) */
/* WARNING: Removing unreachable block (ram,0x015352f4) */
/* WARNING: Removing unreachable block (ram,0x01535318) */
/* WARNING: Removing unreachable block (ram,0x0153533c) */
/* WARNING: Removing unreachable block (ram,0x015353a8) */
/* WARNING: Removing unreachable block (ram,0x01535350) */
/* WARNING: Removing unreachable block (ram,0x015353bc) */
/* WARNING: Removing unreachable block (ram,0x01535368) */
/* WARNING: Removing unreachable block (ram,0x015353d4) */
/* WARNING: Removing unreachable block (ram,0x0153537c) */
/* WARNING: Removing unreachable block (ram,0x015353e8) */
/* WARNING: Removing unreachable block (ram,0x01535394) */
/* WARNING: Removing unreachable block (ram,0x015353fc) */
/* WARNING: Removing unreachable block (ram,0x015354f4) */
/* WARNING: Removing unreachable block (ram,0x01535410) */
/* WARNING: Removing unreachable block (ram,0x01535504) */
/* WARNING: Removing unreachable block (ram,0x01535424) */
/* WARNING: Removing unreachable block (ram,0x0153551c) */
/* WARNING: Removing unreachable block (ram,0x01535438) */
/* WARNING: Removing unreachable block (ram,0x01535530) */
/* WARNING: Removing unreachable block (ram,0x01535450) */
/* WARNING: Removing unreachable block (ram,0x0153554c) */
/* WARNING: Removing unreachable block (ram,0x01535468) */
/* WARNING: Removing unreachable block (ram,0x0153555c) */
/* WARNING: Removing unreachable block (ram,0x0153547c) */
/* WARNING: Removing unreachable block (ram,0x01535570) */
/* WARNING: Removing unreachable block (ram,0x0153548c) */
/* WARNING: Removing unreachable block (ram,0x01535580) */
/* WARNING: Removing unreachable block (ram,0x015354a0) */
/* WARNING: Removing unreachable block (ram,0x0153559c) */
/* WARNING: Removing unreachable block (ram,0x015354b8) */
/* WARNING: Removing unreachable block (ram,0x015355ac) */
/* WARNING: Removing unreachable block (ram,0x015354cc) */
/* WARNING: Removing unreachable block (ram,0x015355c0) */
/* WARNING: Removing unreachable block (ram,0x015354dc) */
/* WARNING: Removing unreachable block (ram,0x015355d0) */
/* WARNING: Removing unreachable block (ram,0x015354f0) */
/* WARNING: Removing unreachable block (ram,0x015353a4) */
/* WARNING: Removing unreachable block (ram,0x015355d4) */
/* WARNING: Removing unreachable block (ram,0x015355d8) */
/* WARNING: Removing unreachable block (ram,0x01535644) */
/* WARNING: Removing unreachable block (ram,0x015355ec) */
/* WARNING: Removing unreachable block (ram,0x01535658) */
/* WARNING: Removing unreachable block (ram,0x01535604) */
/* WARNING: Removing unreachable block (ram,0x01535670) */
/* WARNING: Removing unreachable block (ram,0x01535618) */
/* WARNING: Removing unreachable block (ram,0x01535684) */
/* WARNING: Removing unreachable block (ram,0x01535630) */
/* WARNING: Removing unreachable block (ram,0x01535640) */
/* WARNING: Removing unreachable block (ram,0x01535698) */
/* WARNING: Removing unreachable block (ram,0x01535790) */
/* WARNING: Removing unreachable block (ram,0x015356ac) */
/* WARNING: Removing unreachable block (ram,0x015357a0) */
/* WARNING: Removing unreachable block (ram,0x015356c0) */
/* WARNING: Removing unreachable block (ram,0x015357b8) */
/* WARNING: Removing unreachable block (ram,0x015356d4) */
/* WARNING: Removing unreachable block (ram,0x015357cc) */
/* WARNING: Removing unreachable block (ram,0x015356ec) */
/* WARNING: Removing unreachable block (ram,0x015357e8) */
/* WARNING: Removing unreachable block (ram,0x01535704) */
/* WARNING: Removing unreachable block (ram,0x015357f8) */
/* WARNING: Removing unreachable block (ram,0x01535718) */
/* WARNING: Removing unreachable block (ram,0x0153580c) */
/* WARNING: Removing unreachable block (ram,0x01535728) */
/* WARNING: Removing unreachable block (ram,0x0153581c) */
/* WARNING: Removing unreachable block (ram,0x0153573c) */
/* WARNING: Removing unreachable block (ram,0x01535838) */
/* WARNING: Removing unreachable block (ram,0x01535754) */
/* WARNING: Removing unreachable block (ram,0x01535848) */
/* WARNING: Removing unreachable block (ram,0x01535768) */
/* WARNING: Removing unreachable block (ram,0x0153585c) */
/* WARNING: Removing unreachable block (ram,0x01535778) */
/* WARNING: Removing unreachable block (ram,0x0153578c) */
/* WARNING: Removing unreachable block (ram,0x0153586c) */
/* WARNING: Removing unreachable block (ram,0x01535304) */
/* WARNING: Removing unreachable block (ram,0x01535264) */
/* WARNING: Removing unreachable block (ram,0x01535270) */
/* WARNING: Removing unreachable block (ram,0x01535274) */
/* WARNING: Removing unreachable block (ram,0x0153520c) */
/* WARNING: Removing unreachable block (ram,0x0153587c) */
/* WARNING: Removing unreachable block (ram,0x01535894) */
/* WARNING: Removing unreachable block (ram,0x015358b8) */
/* WARNING: Removing unreachable block (ram,0x015358d4) */
/* WARNING: Removing unreachable block (ram,0x015358e8) */
/* WARNING: Removing unreachable block (ram,0x015358f4) */
/* WARNING: Removing unreachable block (ram,0x015358c8) */
/* WARNING: Removing unreachable block (ram,0x01534c88) */
/* WARNING: Removing unreachable block (ram,0x015358d0) */
/* WARNING: Removing unreachable block (ram,0x015358f8) */
/* WARNING: Removing unreachable block (ram,0x015358a0) */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

segment_command *
__ZN5Proxy14LoadSturdyJPEGERNSt3__114basic_ifstreamIcNS0_11char_traitsIcEEEER12CImageBufferiiib
          (long *param_1,long param_2,long param_3,segment_command *param_4,char *param_5,
          segment_command *param_6,segment_command *param_7)

{
  byte bVar1;
  uint uVar2;
  uint uVar3;
  undefined8 uVar4;
  ulong uVar5;
  code *pcVar6;
  segment_command **ppsVar7;
  segment_command **ppsVar8;
  undefined1 *puVar9;
  bool bVar11;
  int iVar12;
  uint uVar13;
  uint uVar14;
  undefined4 uVar15;
  ushort *puVar16;
  undefined2 *puVar17;
  undefined8 uVar18;
  ulong uVar19;
  undefined8 *puVar20;
  segment_command *psVar21;
  long *plVar22;
  segment_command *psVar23;
  long lVar24;
  long *plVar25;
  long *plVar26;
  undefined4 uVar28;
  long *plVar27;
  segment_command *psVar29;
  segment_command *psVar30;
  ushort *puVar31;
  undefined4 uVar32;
  segment_command *psVar33;
  segment_command *psVar34;
  segment_command *psVar35;
  uint uVar36;
  segment_command *psVar37;
  ulong uVar38;
  long *plVar39;
  int *piVar40;
  segment_command *psVar41;
  long lVar42;
  undefined4 *puVar43;
  byte *pbVar44;
  float *pfVar45;
  dword *pdVar46;
  undefined2 *puVar47;
  ulong uVar48;
  long lVar49;
  segment_command *psVar50;
  float *pfVar51;
  segment_command *psVar52;
  segment_command *unaff_x21;
  segment_command *psVar53;
  long *plVar54;
  segment_command *unaff_x22;
  uint *puVar55;
  segment_command *unaff_x23;
  segment_command *unaff_x27;
  segment_command *psVar56;
  uint *puVar57;
  long *plVar58;
  char *pcVar59;
  undefined4 *puVar60;
  undefined1 *puVar61;
  int iVar62;
  uint uVar63;
  float fVar64;
  int iVar67;
  int iVar68;
  int iVar69;
  undefined1 auVar65 [16];
  undefined1 auVar66 [16];
  float fVar70;
  float fVar71;
  float fVar72;
  float fVar73;
  float fVar76;
  float fVar77;
  undefined1 auVar74 [16];
  undefined1 auVar75 [16];
  float fVar78;
  float fVar79;
  float fVar80;
  float fVar81;
  float fVar84;
  float fVar85;
  undefined1 auVar82 [16];
  undefined1 auVar83 [16];
  float fVar86;
  undefined1 auVar87 [16];
  undefined1 auVar88 [16];
  int iVar89;
  float fVar90;
  int iVar91;
  float fVar92;
  int iVar93;
  float fVar94;
  int iVar95;
  float fVar96;
  float fVar97;
  float fVar100;
  float fVar101;
  undefined1 auVar98 [16];
  undefined1 auVar99 [16];
  float fVar102;
  float fVar103;
  float fVar106;
  float fVar107;
  undefined1 auVar104 [16];
  undefined1 auVar105 [16];
  float fVar108;
  undefined1 auVar109 [16];
  undefined1 auVar110 [16];
  undefined1 auVar111 [16];
  undefined8 unaff_d8;
  undefined8 unaff_d9;
  undefined8 unaff_d10;
  undefined8 unaff_d11;
  undefined1 auVar112 [12];
  undefined1 auVar113 [16];
  undefined1 auVar114 [16];
  undefined1 auVar115 [16];
  segment_command *psStack_4f0;
  double dStack_4e8;
  long lStack_4d8;
  long lStack_4d0;
  uint uStack_4c8;
  uint uStack_4c4;
  undefined8 uStack_4c0;
  uint uStack_4b4;
  uint uStack_4b0;
  int iStack_4ac;
  int *piStack_4a8;
  uint uStack_49c;
  long lStack_498;
  long lStack_490;
  segment_command *psStack_488;
  segment_command *psStack_480;
  long lStack_478;
  long lStack_470;
  uint uStack_464;
  segment_command *psStack_460;
  segment_command *psStack_458;
  long lStack_450;
  segment_command *psStack_448;
  ulong uStack_440;
  undefined8 uStack_438;
  long lStack_428;
  long lStack_420;
  undefined8 uStack_418;
  segment_command *psStack_410;
  undefined8 uStack_408;
  long lStack_3f8;
  segment_command asStack_3e8 [7];
  undefined1 auStack_1d8 [80];
  segment_command sStack_188;
  int iStack_134;
  int iStack_130;
  int iStack_12c;
  ushort auStack_128 [2];
  uint uStack_124;
  uint uStack_120;
  int iStack_11c;
  uint auStack_118 [8];
  int aiStack_f8 [12];
  int aiStack_c8 [10];
  uint auStack_a0 [10];
  ushort uStack_78;
  ushort uStack_76;
  ushort uStack_74;
  long alStack_70 [2];
  segment_command **ppsVar10;

  puVar61 = &stack0xfffffffffffffff0;
  ppsVar10 = &psStack_4f0;
  ppsVar8 = &psStack_4f0;
  ppsVar7 = &psStack_4f0;
  alStack_70[0] = *(long *)PTR____stack_chk_guard_01d15188;
  psVar53 = (segment_command *)&MACH_HEADER.filetype;
  psVar30 = param_4;
  psVar34 = (segment_command *)param_5;
  psVar23 = param_6;
  lStack_3f8 = param_2;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(param_1,&iStack_134);
  if (((*(int *)((long)param_1 + *(long *)(*param_1 + -0x18) + 0x20) != 0) ||
      (iStack_134 != 0x47504a53 || iStack_130 != -0x35014542)) || (iStack_12c - 0xc5U < 0xfffffff7))
  {
    psVar50 = (segment_command *)0x0;
    psVar56 = param_7;
    goto LAB_01534814;
  }
  psVar53 = (segment_command *)(ulong)(iStack_12c - 0xc);
  lStack_478 = (long)iStack_12c;
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(param_1,auStack_128);
  psVar50 = (segment_command *)0x0;
  psVar56 = param_7;
  if (*(int *)((long)param_1 + *(long *)(*param_1 + -0x18) + 0x20) != 0 || 3 < auStack_128[0])
  goto LAB_01534814;
  uVar63 = uStack_124;
  if ((int)uStack_124 < 0) {
    uVar63 = uStack_124 + 1;
  }
  iVar12 = (int)param_3;
  uStack_4b0 = uStack_124;
  uStack_4b4 = uStack_120;
  if (((0 < iVar12) && (iVar62 = (int)param_4, 0 < iVar62)) && (iVar12 <= (int)uVar63 >> 1)) {
    psVar50 = (segment_command *)0x0;
    if ((int)uStack_120 < 0) {
      uStack_120 = uStack_120 + 1;
    }
    if ((iVar62 <= (int)uStack_120 >> 1) && (0 < iStack_11c)) {
      psVar53 = (segment_command *)((long)&MACH_HEADER.magic + 1);
      uVar13 = (int)uStack_120 >> 1;
      uVar63 = (int)uVar63 >> 1;
      do {
        uStack_4b0 = uVar63;
        uStack_4b4 = uVar13;
        psVar50 = psVar53;
        uVar63 = uStack_4b0;
        if ((int)uStack_4b0 < 0) {
          uVar63 = uStack_4b0 + 1;
        }
        if ((int)uVar63 >> 1 < iVar12) break;
        uVar14 = uStack_4b4;
        if ((int)uStack_4b4 < 0) {
          uVar14 = uStack_4b4 + 1;
        }
        psVar53 = (segment_command *)(ulong)((int)psVar50 + 1);
        uVar13 = (int)uVar14 >> 1;
        uVar63 = (int)uVar63 >> 1;
      } while (iVar62 <= (int)uVar14 >> 1 && (int)psVar50 < iStack_11c);
    }
  }
  psVar34 = (segment_command *)((long)&MACH_HEADER.magic + 3);
  psVar23 = &segment_command_00000020;
  func_0x01195d64(lStack_3f8);
  piStack_4a8 = aiStack_c8 + (long)psVar50;
  lVar42 = (long)*piStack_4a8 * (long)(int)auStack_a0[(long)psVar50];
  unaff_x22 = (segment_command *)(lVar42 * 3);
  iVar12 = (int)psVar50;
  if (iStack_11c < iVar12) {
    iVar62 = 0;
    unaff_x21 = (segment_command *)0x0;
  }
  else {
    if ((uint)(iStack_11c - iVar12) < 0xf) {
      iVar62 = 0;
      psVar53 = psVar50;
LAB_01534a14:
      iVar67 = (iStack_11c - (int)psVar53) + 1;
      piVar40 = aiStack_c8 + (long)psVar53;
      do {
        iVar62 = iVar62 + piVar40[10] * *piVar40 * 0xc;
        iVar67 = iVar67 + -1;
        piVar40 = piVar40 + 1;
      } while (iVar67 != 0);
    }
    else {
      uVar19 = (ulong)(uint)(iStack_11c - iVar12) + 1;
      uVar48 = uVar19 & 0x1fffffff0;
      psVar53 = (segment_command *)((long)psVar50->segname + (uVar48 - 8));
      puVar20 = (undefined8 *)((long)alStack_70 + (long)psVar50 * 4);
      iVar62 = 0;
      iVar67 = 0;
      iVar68 = 0;
      iVar69 = 0;
      iVar89 = 0;
      iVar91 = 0;
      iVar93 = 0;
      iVar95 = 0;
      uVar38 = uVar48;
      auVar115 = ZEXT816(0);
      auVar75 = ZEXT816(0);
      do {
        iVar62 = iVar62 + *(int *)(puVar20 + -6) * (int)puVar20[-0xb] * 0xc;
        iVar67 = iVar67 + *(int *)((long)puVar20 + -0x2c) * (int)((ulong)puVar20[-0xb] >> 0x20) *
                          0xc;
        iVar68 = iVar68 + *(int *)(puVar20 + -5) * (int)puVar20[-10] * 0xc;
        iVar69 = iVar69 + *(int *)((long)puVar20 + -0x24) * (int)((ulong)puVar20[-10] >> 0x20) * 0xc
        ;
        auVar83._0_4_ = auVar115._0_4_ + *(int *)(puVar20 + -4) * (int)puVar20[-9] * 0xc;
        auVar83._4_4_ =
             auVar115._4_4_ +
             *(int *)((long)puVar20 + -0x1c) * (int)((ulong)puVar20[-9] >> 0x20) * 0xc;
        auVar83._8_4_ = auVar115._8_4_ + *(int *)(puVar20 + -3) * (int)puVar20[-8] * 0xc;
        auVar83._12_4_ =
             auVar115._12_4_ +
             *(int *)((long)puVar20 + -0x14) * (int)((ulong)puVar20[-8] >> 0x20) * 0xc;
        auVar88._0_4_ = auVar75._0_4_ + *(int *)(puVar20 + -2) * (int)puVar20[-7] * 0xc;
        auVar88._4_4_ =
             auVar75._4_4_ +
             *(int *)((long)puVar20 + -0xc) * (int)((ulong)puVar20[-7] >> 0x20) * 0xc;
        auVar88._8_4_ = auVar75._8_4_ + *(int *)(puVar20 + -1) * (int)puVar20[-6] * 0xc;
        auVar88._12_4_ =
             auVar75._12_4_ + *(int *)((long)puVar20 + -4) * (int)((ulong)puVar20[-6] >> 0x20) * 0xc
        ;
        iVar89 = iVar89 + (int)*puVar20 * (int)puVar20[-5] * 0xc;
        iVar91 = iVar91 + (int)((ulong)*puVar20 >> 0x20) * (int)((ulong)puVar20[-5] >> 0x20) * 0xc;
        iVar93 = iVar93 + (int)puVar20[1] * (int)puVar20[-4] * 0xc;
        iVar95 = iVar95 + (int)((ulong)puVar20[1] >> 0x20) * (int)((ulong)puVar20[-4] >> 0x20) * 0xc
        ;
        puVar20 = puVar20 + 8;
        uVar38 = uVar38 - 0x10;
        auVar115 = auVar83;
        auVar75 = auVar88;
      } while (uVar38 != 0);
      iVar62 = iVar89 + auVar88._0_4_ + auVar83._0_4_ + iVar62 +
               iVar91 + auVar88._4_4_ + auVar83._4_4_ + iVar67 +
               iVar93 + auVar88._8_4_ + auVar83._8_4_ + iVar68 +
               iVar95 + auVar88._12_4_ + auVar83._12_4_ + iVar69;
      if (uVar19 != uVar48) goto LAB_01534a14;
    }
    if ((uint)(iStack_11c - iVar12) < 0xf) {
      unaff_x21 = (segment_command *)0x0;
      psVar53 = psVar50;
    }
    else {
      uVar19 = (ulong)(uint)(iStack_11c - iVar12) + 1;
      uVar48 = uVar19 & 0x1fffffff0;
      psVar53 = (segment_command *)((long)psVar50->segname + (uVar48 - 8));
      piVar40 = aiStack_f8 + (long)psVar50;
      auVar115 = ZEXT816(0);
      auVar75 = ZEXT816(0);
      auVar83 = ZEXT816(0);
      auVar88 = ZEXT816(0);
      uVar38 = uVar48;
      do {
        auVar105._0_4_ = (int)*(undefined8 *)(piVar40 + 6) + piVar40[-4];
        auVar105._4_4_ = (int)((ulong)*(undefined8 *)(piVar40 + 6) >> 0x20) + piVar40[-3];
        auVar105._8_4_ = (int)*(undefined8 *)(piVar40 + 8) + piVar40[-2];
        auVar105._12_4_ = (int)((ulong)*(undefined8 *)(piVar40 + 8) >> 0x20) + piVar40[-1];
        auVar111._0_4_ = (int)*(undefined8 *)(piVar40 + 10) + *piVar40;
        auVar111._4_4_ = (int)((ulong)*(undefined8 *)(piVar40 + 10) >> 0x20) + piVar40[1];
        auVar111._8_4_ = (int)*(undefined8 *)(piVar40 + 0xc) + piVar40[2];
        auVar111._12_4_ = (int)((ulong)*(undefined8 *)(piVar40 + 0xc) >> 0x20) + piVar40[3];
        auVar109._0_4_ = (int)*(undefined8 *)(piVar40 + 0xe) + piVar40[4];
        auVar109._4_4_ = (int)((ulong)*(undefined8 *)(piVar40 + 0xe) >> 0x20) + piVar40[5];
        auVar109._8_4_ = (int)*(undefined8 *)(piVar40 + 0x10) + piVar40[6];
        auVar109._12_4_ = (int)((ulong)*(undefined8 *)(piVar40 + 0x10) >> 0x20) + piVar40[7];
        auVar99._4_4_ =
             (int)((ulong)*(undefined8 *)(piVar40 + 2) >> 0x20) +
             (int)((ulong)*(undefined8 *)(piVar40 + -8) >> 0x20);
        auVar99._0_4_ = (int)*(undefined8 *)(piVar40 + 2) + (int)*(undefined8 *)(piVar40 + -8);
        auVar99._8_4_ = (int)*(undefined8 *)(piVar40 + 4) + (int)*(undefined8 *)(piVar40 + -6);
        auVar99._12_4_ =
             (int)((ulong)*(undefined8 *)(piVar40 + 4) >> 0x20) +
             (int)((ulong)*(undefined8 *)(piVar40 + -6) >> 0x20);
        auVar115 = NEON_smax(auVar99,auVar115,4);
        auVar75 = NEON_smax(auVar105,auVar75,4);
        auVar83 = NEON_smax(auVar111,auVar83,4);
        auVar88 = NEON_smax(auVar109,auVar88,4);
        piVar40 = piVar40 + 0x10;
        uVar38 = uVar38 - 0x10;
      } while (uVar38 != 0);
      auVar115 = NEON_smax(auVar115,auVar75,4);
      auVar115 = NEON_smax(auVar115,auVar83,4);
      auVar115 = NEON_smax(auVar115,auVar88,4);
      uVar63 = NEON_smaxv(auVar115,4);
      unaff_x21 = (segment_command *)(ulong)uVar63;
      if (uVar19 == uVar48) goto LAB_01534b18;
    }
    iVar67 = (iStack_11c - (int)psVar53) + 1;
    piVar40 = aiStack_f8 + (long)((long)&psVar53->cmd + 2);
    do {
      uVar63 = *piVar40 + piVar40[-10];
      if (*piVar40 + piVar40[-10] <= (int)(uint)unaff_x21) {
        uVar63 = (uint)unaff_x21;
      }
      unaff_x21 = (segment_command *)(ulong)uVar63;
      iVar67 = iVar67 + -1;
      piVar40 = piVar40 + 1;
    } while (iVar67 != 0);
  }
LAB_01534b18:
  unaff_x23 = (segment_command *)(ulong)(iStack_11c < iVar12);
  iVar68 = auStack_a0[(long)psVar50] * 4;
  iVar67 = iVar68 + 0x1c;
  iVar68 = iVar68 + 0x23;
  if (-1 < iVar67) {
    iVar68 = iVar67;
  }
  lVar24 = (long)((iVar68 >> 3) + (int)unaff_x22 * 4 + iVar62 + (int)unaff_x21) + 0x28;
  psStack_488 = psVar50;
  lStack_428 = __Znam(lVar24);
  uStack_49c = (uint)param_6;
  lStack_420 = lStack_428 + lVar24;
  lStack_490 = (long)unaff_x22->segname + lStack_428 + -8;
  lStack_498 = (long)unaff_x22->segname + lStack_490 + -8;
  unaff_x27 = (segment_command *)((long)unaff_x22->segname + lStack_498 + -8);
  lStack_450 = (long)unaff_x22->segname + (long)((long)unaff_x27->segname + -0x10);
  psVar30 = (segment_command *)param_5;
  psStack_458 = (segment_command *)(long)iStack_11c;
  if (iStack_11c >= iVar12) {
    unaff_x23 = (segment_command *)auStack_1d8;
    lVar24 = (long)unaff_x21->segname + lStack_450 + -8;
    param_4 = (segment_command *)(ulong)((iStack_11c - (int)psStack_488) + 1);
    piVar40 = piStack_4a8;
    pcVar59 = sStack_188.segname + (long)psStack_488 * 8 + -8;
    do {
      lVar49 = (long)piVar40[10] * (long)(*piVar40 * 3) * 4;
      auStack_1d8._0_8_ = lStack_420 - lVar24;
      psVar30 = (segment_command *)auStack_1d8;
      asStack_3e8[0]._0_8_ = lVar24;
      lVar24 = __ZNSt3__15alignEmmRPvRm(4,lVar49,asStack_3e8);
      piVar40 = piVar40 + 1;
      param_6 = (segment_command *)(pcVar59 + 8);
      *(long *)pcVar59 = lVar24;
      lVar24 = lVar49 + lVar24;
      uVar63 = (int)param_4 - 1;
      param_4 = (segment_command *)(ulong)uVar63;
      pcVar59 = (char *)param_6;
    } while (uVar63 != 0);
  }
  lStack_470 = func_0x0074b028();
  lVar24 = lStack_478;
  psVar53 = (segment_command *)(long)((int)unaff_x21 - (int)lStack_478);
  __ZNSt3__113basic_istreamIcNS_11char_traitsIcEEE4readEPcl(param_1,lStack_450 + lStack_478);
  if (*(int *)((long)param_1 + *(long *)(*param_1 + -0x18) + 0x20) == 0) {
    uStack_4c8 = 1;
    if ((int)psStack_488 <= (int)psStack_458) {
      psStack_480 = (segment_command *)(long)(int)psStack_488;
      lStack_4d0 = lVar42 * 0xc;
      lStack_4d8 = lStack_428 + (lVar42 * 3 + 8) * 4;
      unaff_x23 = (segment_command *)0x100000000;
      psVar56 = psStack_458;
      do {
        psVar50 = psVar56;
        lVar42 = func_0x0074b028();
        pcVar59 = (char *)((long)&psVar50->cmd + 1);
        *(double *)(auStack_1d8 + (long)pcVar59 * 8) = (double)(ulong)(lVar42 - lStack_470) * 1e-06;
        uVar19 = (ulong)auStack_118[(long)psVar50];
        unaff_x22 = (segment_command *)(lStack_450 + uVar19);
        param_6 = *(segment_command **)(sStack_188.segname + (long)psVar50 * 8 + -8);
        iVar12 = aiStack_c8[(long)psVar50];
        psStack_410 = (segment_command *)(ulong)auStack_a0[(long)psVar50];
        uStack_440 = CONCAT44(uStack_440._4_4_,iVar12);
        uVar63 = iVar12 * 3;
        psStack_448 = (segment_command *)(ulong)uVar63;
        psStack_460 = psVar50;
        if (psVar50 != psStack_458) {
          uStack_4c0 = *(undefined8 *)(sStack_188.segname + (long)&psVar50->cmd * 8);
          iStack_4ac = aiStack_c8[(long)pcVar59];
          uStack_4c4 = auStack_a0[(long)pcVar59];
          uVar63 = unaff_x22->cmdsize;
          param_5 = (char *)(ulong)uVar63;
          bVar11 = (uStack_49c & psVar50 == psStack_480) == 0;
          uStack_464 = 0;
          if (bVar11) {
            uStack_464 = (uint)unaff_x22->fileoff;
          }
          psVar50 = (segment_command *)(long)(int)*(dword *)((long)&unaff_x22->vmsize + 4);
          uVar13 = 0;
          if (bVar11) {
            uVar13 = (uint)unaff_x22->vmsize;
          }
          psVar53 = (segment_command *)(ulong)uVar13;
          uVar19 = (ulong)(int)*(dword *)((long)&unaff_x22->vmaddr + 4);
          uVar14 = 0;
          if (bVar11) {
            uVar14 = (uint)unaff_x22->vmaddr;
          }
          psVar41 = (segment_command *)(ulong)uVar14;
          asStack_3e8[0].cmd = 0;
          asStack_3e8[0].cmdsize = 0;
          asStack_3e8[0].segname[0] = '\x01';
          if ((int)uVar14 < 1) {
            if (0 < (int)uVar13) {
              param_7 = psVar53;
              func_0x01537114(asStack_3e8,lStack_490,iVar12,psStack_410,psStack_448,
                              (long)unaff_x22->segname + (uVar19 - 8));
            }
            if ((int)uStack_464 < 1) {
              auVar75._8_4_ = uVar14;
              auVar75._0_8_ = &sStack_188;
              auVar75._12_4_ = 0;
              if (0 < (int)uVar63) {
                param_7 = (segment_command *)param_5;
                func_0x01537114(asStack_3e8,unaff_x27,uStack_440 & 0xffffffff,psStack_410,
                                psStack_448,
                                (long)unaff_x22->segname +
                                (long)(int)(uint)*(qword *)&unaff_x22->cmd + -8);
              }
              psVar21 = asStack_3e8;
              uVar18 = 0x1534fa8;
              goto __ZN5Proxy13tjpg_plan_runEP22tjpg_plan_decompress_t;
            }
            psVar30 = (segment_command *)
                      ((long)psVar50->segname + (long)((long)unaff_x22->segname + -0x10));
            auVar115._8_8_ = lStack_498;
            auVar115._0_8_ = asStack_3e8;
            param_7 = (segment_command *)(ulong)uStack_464;
            uVar18 = 0x1534f70;
            psVar34 = psStack_448;
            goto __ZN5Proxy13tjpg_plan_addEP22tjpg_plan_decompress_tPhiiiPKvi;
          }
          psVar30 = (segment_command *)
                    ((long)unaff_x22->segname + (long)*(int *)((long)unaff_x22->segname + 0xc) + -8)
          ;
          auVar115._8_8_ = lStack_428;
          auVar115._0_8_ = asStack_3e8;
          uVar18 = 0x1534f1c;
          ppsVar8 = &psStack_4f0;
          psVar34 = psStack_448;
          param_7 = psVar41;
          goto __ZN5Proxy13tjpg_plan_addEP22tjpg_plan_decompress_tPhiiiPKvi;
        }
        if ((0 < (int)auStack_a0[(long)psVar50]) && (0 < iVar12)) {
          lVar42 = 0;
          psVar56 = (segment_command *)0x0;
          uVar13 = uVar63;
          if ((int)uVar63 < 2) {
            uVar13 = 1;
          }
          psVar41 = (segment_command *)(ulong)uVar13;
          uVar38 = -(ulong)(uVar63 >> 0x1f) & 0xfffffffc00000000 | (long)psStack_448 << 2;
          uVar48 = -(ulong)(uVar63 >> 0x1f) & 0xfffffffe00000000 | (long)psStack_448 << 1;
          psVar21 = (segment_command *)((ulong)psVar41 & 0x7fffffe0);
          pdVar46 = &param_6->nsects;
          puVar16 = (ushort *)(lStack_4d8 + uVar19);
          do {
            if ((uVar13 < 0x20) ||
               (lVar24 = uVar38 * (long)psVar56,
               psVar23 = (segment_command *)
                         ((long)param_6->segname + (long)psVar41 * 4 + lVar24 + -8),
               puVar31 = puVar16, psVar30 = (segment_command *)pdVar46, psVar53 = psVar21,
               (ulong)((long)param_6->segname + lVar24 + -8) <
               lStack_428 + uVar48 * (long)psVar56 + lStack_4d0 + uVar19 + (long)psVar41 * 2 &&
               (segment_command *)(lStack_428 + uVar48 * (long)psVar56 + lStack_4d0 + uVar19) <
               psVar23)) {
              psVar53 = (segment_command *)0x0;
LAB_01534e64:
              lVar24 = (long)psVar41 - (long)psVar53;
              pfVar51 = (float *)((long)param_6->segname +
                                 (long)psVar53->segname * 4 + lVar42 * 4 + -0x28);
              psVar53 = (segment_command *)((long)unaff_x22->segname + (long)psVar53 * 2 + -8);
              do {
                psVar34 = (segment_command *)((long)&psVar53->cmd + 2);
                psVar23 = (segment_command *)(ulong)(ushort)*(qword *)&psVar53->cmd;
                psVar30 = (segment_command *)(pfVar51 + 1);
                *pfVar51 = (float)(long)psVar23;
                lVar24 = lVar24 + -1;
                pfVar51 = (float *)psVar30;
                psVar53 = psVar34;
              } while (lVar24 != 0);
            }
            else {
              do {
                auVar82._2_2_ = 0;
                auVar82._0_2_ = puVar31[-0x10];
                auVar82._4_2_ = puVar31[-0xf];
                auVar82._6_2_ = 0;
                auVar82._8_2_ = puVar31[-0xe];
                auVar82._10_2_ = 0;
                auVar82._12_2_ = puVar31[-0xd];
                auVar82._14_2_ = 0;
                uVar4 = *(undefined8 *)(puVar31 + 0xc);
                uVar18 = *(undefined8 *)(puVar31 + 8);
                auVar83 = NEON_ucvtf(auVar82,4);
                auVar65._2_2_ = 0;
                auVar65._0_2_ = puVar31[-0xc];
                auVar65._4_2_ = puVar31[-0xb];
                auVar65._6_2_ = 0;
                auVar65._8_2_ = puVar31[-10];
                auVar65._10_2_ = 0;
                auVar65._12_2_ = puVar31[-9];
                auVar65._14_2_ = 0;
                auVar115 = NEON_ucvtf(auVar65,4);
                auVar98._2_2_ = 0;
                auVar98._0_2_ = puVar31[-8];
                auVar98._4_2_ = puVar31[-7];
                auVar98._6_2_ = 0;
                auVar98._8_2_ = puVar31[-6];
                auVar98._10_2_ = 0;
                auVar98._12_2_ = puVar31[-5];
                auVar98._14_2_ = 0;
                auVar99 = NEON_ucvtf(auVar98,4);
                auVar74._2_2_ = 0;
                auVar74._0_2_ = puVar31[-4];
                auVar74._4_2_ = puVar31[-3];
                auVar74._6_2_ = 0;
                auVar74._8_2_ = puVar31[-2];
                auVar74._10_2_ = 0;
                auVar74._12_2_ = puVar31[-1];
                auVar74._14_2_ = 0;
                auVar75 = NEON_ucvtf(auVar74,4);
                auVar104._2_2_ = 0;
                auVar104._0_2_ = *puVar31;
                auVar104._4_2_ = puVar31[1];
                auVar104._6_2_ = 0;
                auVar104._8_2_ = puVar31[2];
                auVar104._10_2_ = 0;
                auVar104._12_2_ = puVar31[3];
                auVar104._14_2_ = 0;
                auVar105 = NEON_ucvtf(auVar104,4);
                auVar87._2_2_ = 0;
                auVar87._0_2_ = puVar31[4];
                auVar87._4_2_ = puVar31[5];
                auVar87._6_2_ = 0;
                auVar87._8_2_ = puVar31[6];
                auVar87._10_2_ = 0;
                auVar87._12_2_ = puVar31[7];
                auVar87._14_2_ = 0;
                auVar88 = NEON_ucvtf(auVar87,4);
                auVar110._2_2_ = 0;
                auVar110._0_2_ = (ushort)uVar18;
                auVar110._4_2_ = (short)((ulong)uVar18 >> 0x10);
                auVar110._6_2_ = 0;
                auVar110._8_2_ = (short)((ulong)uVar18 >> 0x20);
                auVar110._10_2_ = 0;
                auVar110._12_2_ = (short)((ulong)uVar18 >> 0x30);
                auVar110._14_2_ = 0;
                auVar111 = NEON_ucvtf(auVar110,4);
                *(long *)((long)psVar30 + -0x38) = auVar83._8_8_;
                ((segment_command *)((long)psVar30 + -0x40))->cmd = (int)auVar83._0_8_;
                ((segment_command *)((long)psVar30 + -0x40))->cmdsize =
                     (int)((ulong)auVar83._0_8_ >> 0x20);
                *(qword *)((long)psVar30 + -0x28) = auVar115._8_8_;
                *(long *)((long)psVar30 + -0x30) = auVar115._0_8_;
                auVar66._2_2_ = 0;
                auVar66._0_2_ = (ushort)uVar4;
                auVar66._4_2_ = (short)((ulong)uVar4 >> 0x10);
                auVar66._6_2_ = 0;
                auVar66._8_2_ = (short)((ulong)uVar4 >> 0x20);
                auVar66._10_2_ = 0;
                auVar66._12_2_ = (short)((ulong)uVar4 >> 0x30);
                auVar66._14_2_ = 0;
                *(qword *)((long)psVar30 + -0x18) = auVar99._8_8_;
                *(qword *)((long)psVar30 + -0x20) = auVar99._0_8_;
                *(long *)((long)psVar30 + -8) = auVar75._8_8_;
                *(qword *)((long)psVar30 + -0x10) = auVar75._0_8_;
                *(long *)((long)psVar30 + 8) = auVar105._8_8_;
                *(long *)psVar30 = auVar105._0_8_;
                *(long *)((long)psVar30 + 0x18) = auVar88._8_8_;
                *(long *)((long)psVar30 + 0x10) = auVar88._0_8_;
                auVar115 = NEON_ucvtf(auVar66,4);
                *(long *)((long)psVar30 + 0x28) = auVar111._8_8_;
                *(long *)((long)psVar30 + 0x20) = auVar111._0_8_;
                *(long *)((long)psVar30 + 0x38) = auVar115._8_8_;
                *(long *)((long)psVar30 + 0x30) = auVar115._0_8_;
                psVar30 = (segment_command *)((long)psVar30 + 0x80);
                psVar34 = psVar53 + -1;
                puVar31 = puVar31 + 0x20;
                psVar53 = (segment_command *)&psVar34->fileoff;
              } while (&psVar34->fileoff != (qword *)0x0);
              psVar34 = psVar21;
              psVar53 = psVar21;
              if (psVar21 != psVar41) goto LAB_01534e64;
            }
            psVar56 = (segment_command *)((long)&psVar56->cmd + 1);
            pdVar46 = (dword *)((long)pdVar46 + uVar38);
            puVar16 = (ushort *)((long)puVar16 + uVar48);
            lVar42 = lVar42 + (int)uVar63;
            unaff_x22 = (segment_command *)((long)unaff_x22->segname + (uVar48 - 8));
            psVar53 = psStack_410;
          } while (psVar56 != psStack_410);
        }
        lVar24 = lStack_478;
        psVar56 = (segment_command *)((long)&psVar50[-1].flags + 3);
      } while ((long)psStack_480 < (long)psVar50);
    }
    param_5 = (char *)psStack_488;
    uStack_4c8 = 1;
    lVar42 = func_0x0074b028();
    param_3 = lStack_428;
    param_4 = psStack_458;
    *(double *)(auStack_1d8 + (long)param_5 * 8) = (double)(ulong)(lVar42 - lStack_470) * 1e-06;
    if ((uStack_4c8 & 1) == 0) {
LAB_01535e04:
      psVar50 = (segment_command *)0x0;
    }
    else {
      auVar75 = ZEXT816(0x3f800000);
      auVar83 = ZEXT816(0x3f800000);
      auVar115 = ZEXT816(0x3f800000);
      if ((0xc3 < (int)lVar24) && (1 < auStack_128[0])) {
        fVar64 = (float)NEON_ucvtf((uint)uStack_78);
        auVar75 = ZEXT416((uint)(32.0 / fVar64));
        fVar64 = (float)NEON_ucvtf((uint)uStack_76);
        auVar83 = ZEXT416((uint)(32.0 / fVar64));
        fVar64 = (float)NEON_ucvtf((uint)uStack_74);
        auVar115 = ZEXT416((uint)(32.0 / fVar64));
      }
      if (auStack_128[0] < 3) {
        pfVar51 = *(float **)(sStack_188.segname + (long)param_5 * 8 + -8);
        uStack_440 = auVar83._0_8_;
        uStack_438 = auVar83._8_8_;
        lStack_420 = auVar115._0_8_;
        uStack_418 = auVar115._8_8_;
        psStack_410 = auVar75._0_8_;
        uStack_408 = auVar75._8_8_;
        puVar17 = (undefined2 *)func_0x01196ea8(lStack_3f8);
        psVar53 = (segment_command *)(ulong)uStack_4b0;
        if ((0 < (int)uStack_4b4) && (0 < (int)uStack_4b0)) {
          uVar19 = 0;
          iVar12 = *piStack_4a8;
          uVar38 = *(ulong *)(lStack_3f8 + 0x38);
          psVar56 = (segment_command *)((ulong)psVar53 & 0xfffffff8);
          do {
            fVar64 = SUB84(psStack_410,0);
            fVar81 = (float)uStack_440;
            fVar73 = (float)lStack_420;
            psVar50 = psVar56;
            pfVar45 = pfVar51;
            puVar47 = puVar17;
            if (uStack_4b0 < 8) {
              psVar50 = (segment_command *)0x0;
LAB_01535b10:
              lVar24 = (long)psVar53 - (long)psVar50;
              lVar42 = (long)psVar50 * 0xc;
              puVar47 = puVar17 + (long)psVar50 * 3;
              do {
                pfVar45 = (float *)((long)pfVar51 + lVar42);
                fVar72 = pfVar45[1];
                fVar80 = pfVar45[2];
                *puVar47 = (short)(int)(fVar64 * *pfVar45);
                puVar47[1] = (short)(int)(fVar81 * fVar72);
                puVar47[2] = (short)(int)(fVar73 * fVar80);
                lVar42 = lVar42 + 0xc;
                puVar47 = puVar47 + 3;
                lVar24 = lVar24 + -1;
              } while (lVar24 != 0);
            }
            else {
              do {
                fVar71 = pfVar45[1];
                fVar79 = pfVar45[2];
                fVar72 = pfVar45[3];
                fVar76 = pfVar45[4];
                fVar84 = pfVar45[5];
                fVar80 = pfVar45[6];
                fVar77 = pfVar45[7];
                fVar85 = pfVar45[8];
                fVar70 = pfVar45[9];
                fVar78 = pfVar45[10];
                fVar86 = pfVar45[0xb];
                fVar90 = pfVar45[0xc];
                fVar97 = pfVar45[0xd];
                fVar103 = pfVar45[0xe];
                fVar92 = pfVar45[0xf];
                fVar100 = pfVar45[0x10];
                fVar106 = pfVar45[0x11];
                fVar94 = pfVar45[0x12];
                fVar101 = pfVar45[0x13];
                fVar107 = pfVar45[0x14];
                fVar96 = pfVar45[0x15];
                fVar102 = pfVar45[0x16];
                fVar108 = pfVar45[0x17];
                *puVar47 = (short)(int)(*pfVar45 * fVar64);
                puVar47[1] = (short)(int)(fVar71 * fVar81);
                puVar47[2] = (short)(int)(fVar79 * fVar73);
                puVar47[3] = (short)(int)(fVar72 * fVar64);
                puVar47[4] = (short)(int)(fVar76 * fVar81);
                puVar47[5] = (short)(int)(fVar84 * fVar73);
                puVar47[6] = (short)(int)(fVar80 * fVar64);
                puVar47[7] = (short)(int)(fVar77 * fVar81);
                puVar47[8] = (short)(int)(fVar85 * fVar73);
                puVar47[9] = (short)(int)(fVar70 * fVar64);
                puVar47[10] = (short)(int)(fVar78 * fVar81);
                puVar47[0xb] = (short)(int)(fVar86 * fVar73);
                puVar47[0xc] = (short)(int)(fVar90 * fVar64);
                puVar47[0xd] = (short)(int)(fVar97 * fVar81);
                puVar47[0xe] = (short)(int)(fVar103 * fVar73);
                puVar47[0xf] = (short)(int)(fVar92 * fVar64);
                puVar47[0x10] = (short)(int)(fVar100 * fVar81);
                puVar47[0x11] = (short)(int)(fVar106 * fVar73);
                puVar47[0x12] = (short)(int)(fVar94 * fVar64);
                puVar47[0x13] = (short)(int)(fVar101 * fVar81);
                puVar47[0x14] = (short)(int)(fVar107 * fVar73);
                puVar47[0x15] = (short)(int)(fVar96 * fVar64);
                puVar47[0x16] = (short)(int)(fVar102 * fVar81);
                puVar47[0x17] = (short)(int)(fVar108 * fVar73);
                psVar41 = psVar50 + -1;
                psVar50 = (segment_command *)&psVar41->nsects;
                pfVar45 = pfVar45 + 0x18;
                puVar47 = puVar47 + 0x18;
              } while (&psVar41->nsects != (dword *)0x0);
              psVar50 = psVar56;
              if (psVar56 != psVar53) goto LAB_01535b10;
            }
            uVar19 = uVar19 + 1;
            puVar17 = (undefined2 *)((long)puVar17 + (uVar38 & 0xfffffffffffffffe));
            pfVar51 = pfVar51 + (uint)(iVar12 * 3);
          } while (uVar19 != uStack_4b4);
        }
      }
      else {
        if (auStack_128[0] != 3) {
          psStack_4f0 = (segment_command *)(ulong)auStack_128[0];
          func_0x00574408("Proxy::LoadSturdyJPEG: unsupported proxy version (%d)");
          goto LAB_01535e04;
        }
        pfVar51 = *(float **)(sStack_188.segname + (long)param_5 * 8 + -8);
        uStack_440 = auVar83._0_8_;
        uStack_438 = auVar83._8_8_;
        lStack_420 = auVar115._0_8_;
        uStack_418 = auVar115._8_8_;
        psStack_410 = auVar75._0_8_;
        uStack_408 = auVar75._8_8_;
        puVar17 = (undefined2 *)func_0x01196ea8(lStack_3f8);
        psVar53 = (segment_command *)(ulong)uStack_4b0;
        if ((0 < (int)uStack_4b4) && (0 < (int)uStack_4b0)) {
          uVar19 = 0;
          iVar12 = *piStack_4a8;
          uVar38 = *(ulong *)(lStack_3f8 + 0x38);
          fVar64 = SUB84(psStack_410,0) / 65535.0;
          fVar73 = (float)uStack_440 / 65535.0;
          psVar56 = (segment_command *)((ulong)psVar53 & 0xfffffff8);
          fVar81 = (float)lStack_420 / 65535.0;
          do {
            psVar50 = psVar56;
            pfVar45 = pfVar51;
            puVar47 = puVar17;
            if (uStack_4b0 < 8) {
              psVar50 = (segment_command *)0x0;
LAB_01535c9c:
              lVar24 = (long)psVar53 - (long)psVar50;
              lVar42 = (long)psVar50 * 0xc;
              puVar47 = puVar17 + (long)psVar50 * 3;
              do {
                pfVar45 = (float *)((long)pfVar51 + lVar42);
                fVar72 = pfVar45[1];
                fVar80 = pfVar45[2];
                *puVar47 = (short)(int)(fVar64 * *pfVar45 * *pfVar45);
                puVar47[1] = (short)(int)(fVar73 * fVar72 * fVar72);
                puVar47[2] = (short)(int)(fVar81 * fVar80 * fVar80);
                lVar42 = lVar42 + 0xc;
                puVar47 = puVar47 + 3;
                lVar24 = lVar24 + -1;
              } while (lVar24 != 0);
            }
            else {
              do {
                fVar90 = pfVar45[2];
                fVar78 = pfVar45[3];
                fVar92 = pfVar45[5];
                fVar79 = pfVar45[6];
                fVar85 = pfVar45[7];
                fVar94 = pfVar45[8];
                fVar84 = pfVar45[9];
                fVar86 = pfVar45[10];
                fVar96 = pfVar45[0xb];
                fVar72 = pfVar45[0xc];
                fVar97 = pfVar45[0xe];
                fVar80 = pfVar45[0xf];
                fVar100 = pfVar45[0x11];
                fVar70 = pfVar45[0x12];
                fVar76 = pfVar45[0x13];
                fVar101 = pfVar45[0x14];
                fVar71 = pfVar45[0x15];
                fVar77 = pfVar45[0x16];
                fVar102 = pfVar45[0x17];
                uVar5 = (ulong)CONCAT24((short)(int)(pfVar45[0x10] * pfVar45[0x10] * fVar73),
                                        (int)(pfVar45[0xd] * pfVar45[0xd] * fVar73)) &
                        0xffffffff0000ffff;
                uVar48 = (ulong)CONCAT24((short)(int)(pfVar45[4] * pfVar45[4] * fVar73),
                                         (int)(pfVar45[1] * pfVar45[1] * fVar73)) &
                         0xffffffff0000ffff;
                *puVar47 = (short)(int)(*pfVar45 * *pfVar45 * fVar64);
                puVar47[1] = (short)uVar48;
                puVar47[2] = (short)(int)(fVar90 * fVar90 * fVar81);
                puVar47[3] = (short)(int)(fVar78 * fVar78 * fVar64);
                puVar47[4] = (short)(uVar48 >> 0x20);
                puVar47[5] = (short)(int)(fVar92 * fVar92 * fVar81);
                puVar47[6] = (short)(int)(fVar79 * fVar79 * fVar64);
                puVar47[7] = (short)(int)(fVar85 * fVar85 * fVar73);
                puVar47[8] = (short)(int)(fVar94 * fVar94 * fVar81);
                puVar47[9] = (short)(int)(fVar84 * fVar84 * fVar64);
                puVar47[10] = (short)(int)(fVar86 * fVar86 * fVar73);
                puVar47[0xb] = (short)(int)(fVar96 * fVar96 * fVar81);
                puVar47[0xc] = (short)(int)(fVar72 * fVar72 * fVar64);
                puVar47[0xd] = (short)uVar5;
                puVar47[0xe] = (short)(int)(fVar97 * fVar97 * fVar81);
                puVar47[0xf] = (short)(int)(fVar80 * fVar80 * fVar64);
                puVar47[0x10] = (short)(uVar5 >> 0x20);
                puVar47[0x11] = (short)(int)(fVar100 * fVar100 * fVar81);
                puVar47[0x12] = (short)(int)(fVar70 * fVar70 * fVar64);
                puVar47[0x13] = (short)(int)(fVar76 * fVar76 * fVar73);
                puVar47[0x14] = (short)(int)(fVar101 * fVar101 * fVar81);
                puVar47[0x15] = (short)(int)(fVar71 * fVar71 * fVar64);
                puVar47[0x16] = (short)(int)(fVar77 * fVar77 * fVar73);
                puVar47[0x17] = (short)(int)(fVar102 * fVar102 * fVar81);
                psVar41 = psVar50 + -1;
                psVar50 = (segment_command *)&psVar41->nsects;
                pfVar45 = pfVar45 + 0x18;
                puVar47 = puVar47 + 0x18;
              } while (&psVar41->nsects != (dword *)0x0);
              psVar50 = psVar56;
              if (psVar56 != psVar53) goto LAB_01535c9c;
            }
            uVar19 = uVar19 + 1;
            puVar17 = (undefined2 *)((long)puVar17 + (uVar38 & 0xfffffffffffffffe));
            pfVar51 = pfVar51 + (uint)(iVar12 * 3);
          } while (uVar19 != uStack_4b4);
        }
      }
      if (__DEBUG_DISK_LATENCY != 0) {
        lVar42 = func_0x0074b028();
        unaff_x22 = (segment_command *)((long)&param_4->cmd + 1);
        dStack_4e8 = *(double *)(auStack_1d8 + (long)unaff_x22 * 8) * 1000.0;
        psStack_4f0 = unaff_x21;
        func_0x00574108("Loaded %i bytes in %.2f ms");
        if ((int)param_5 <= (int)param_4) {
          unaff_x21 = (segment_command *)(long)(int)psStack_488;
          unaff_x23 = (segment_command *)auStack_1d8;
          param_1 = (long *)0x408f400000000000;
          param_5 = "Level %i loaded in %.2f ms";
          psVar56 = param_4;
          do {
            dStack_4e8 = (*(double *)
                           ((long)unaff_x23->segname +
                           (undefined1 *)((long)&psVar56[-1].flags + 3) * 8) -
                         *(double *)(auStack_1d8 + (long)psVar56 * 8 + 8)) * 1000.0;
            psStack_4f0 = psVar56;
            func_0x00574108("Level %i loaded in %.2f ms");
            param_4 = (segment_command *)((long)&psVar56[-1].flags + 3);
            bVar11 = (long)unaff_x21 < (long)psVar56;
            psVar56 = param_4;
          } while (bVar11);
        }
        psStack_4f0 = (segment_command *)(ulong)(uint)((int)unaff_x22 - (int)psStack_488);
        dStack_4e8 = (double)(ulong)(lVar42 - lStack_470) * 1e-06 * 1000.0;
        func_0x00574108("Loaded %i levels in %.2f ms");
      }
      psVar50 = (segment_command *)((long)&MACH_HEADER.magic + 1);
    }
  }
  else {
    psVar50 = (segment_command *)0x0;
    param_5 = (char *)psStack_488;
    param_3 = lStack_428;
  }
  __ZdlPv(param_3);
  psVar56 = param_7;
LAB_01534814:
  if (*(long *)PTR____stack_chk_guard_01d15188 == alStack_70[0]) {
    return psVar50;
  }
  uVar18 = ___stack_chk_fail();
  __ZdlPv(lStack_428);
  uVar18 = __Unwind_Resume(uVar18);
  __ZdlPv(lStack_428);
  uVar18 = __Unwind_Resume(uVar18);
  __ZdlPv(lStack_428);
  uVar18 = __Unwind_Resume(uVar18);
  __ZdlPv(lStack_428);
  uVar18 = __Unwind_Resume(uVar18);
  __ZdlPv(lStack_428);
  uVar18 = __Unwind_Resume(uVar18);
  __ZdlPv(lStack_428);
  uVar18 = __Unwind_Resume(uVar18);
  __ZdlPv(lStack_428);
  uVar18 = __Unwind_Resume(uVar18);
  __ZdlPv(lStack_428);
  uVar18 = __Unwind_Resume(uVar18);
  __ZdlPv(lStack_428);
  uVar18 = __Unwind_Resume(uVar18);
  __ZdlPv(lStack_428);
  uVar18 = __Unwind_Resume(uVar18);
  __ZdlPv(lStack_428);
  uVar18 = __Unwind_Resume(uVar18);
  __ZdlPv(lStack_428);
  uVar18 = __Unwind_Resume(uVar18);
  __ZdlPv(lStack_428);
  uVar18 = __Unwind_Resume(uVar18);
  __ZdlPv(lStack_428);
  uVar19 = __Unwind_Resume(uVar18);
  __ZdlPv(lStack_428);
  __Unwind_Resume(uVar19);
  uVar18 = 0x1535f40;
  auVar113 = __Unwind_Resume();
__ZN5Proxy13jpeg_compressEPhiiiiPvi:
  psVar29 = auVar113._8_8_;
  *(undefined8 *)((long)ppsVar7 + -0x70) = unaff_d9;
  *(undefined8 *)((long)ppsVar7 + -0x68) = unaff_d8;
  *(segment_command **)((long)ppsVar7 + -0x60) = param_6;
  *(segment_command **)((long)ppsVar7 + -0x58) = unaff_x27;
  *(long *)((long)ppsVar7 + -0x50) = param_3;
  *(segment_command **)((long)ppsVar7 + -0x48) = param_4;
  *(long **)((long)ppsVar7 + -0x40) = param_1;
  *(segment_command **)((long)ppsVar7 + -0x38) = unaff_x23;
  *(segment_command **)((long)ppsVar7 + -0x30) = unaff_x22;
  *(segment_command **)((long)ppsVar7 + -0x28) = unaff_x21;
  *(char **)((long)ppsVar7 + -0x20) = param_5;
  *(ulong *)((long)ppsVar7 + -0x18) = uVar19;
  *(undefined1 **)((long)ppsVar7 + -0x10) = puVar61;
  *(undefined8 *)((long)ppsVar7 + -8) = uVar18;
  *(undefined8 *)((long)ppsVar7 + -0x78) = *(undefined8 *)PTR____stack_chk_guard_01d15188;
  psVar41 = (segment_command *)((long)ppsVar7 + -0x468);
  psVar50 = psVar53;
  psVar33 = psVar30;
  psVar35 = psVar34;
  psVar37 = psVar23;
  param_7 = psVar56;
  puVar20 = (undefined8 *)func_0x00fc9cf0(psVar41);
  *(undefined8 **)((long)ppsVar7 + -0x300) = puVar20;
  *puVar20 = 0x15360fc;
  iVar12 = _setjmp((undefined1 *)((long)ppsVar7 + -0x3c0));
  if (iVar12 == 1) {
LAB_01535fbc:
    psVar52 = (segment_command *)0xffffffff;
  }
  else {
    psVar41 = (segment_command *)((long)ppsVar7 + -0x300);
    func_0x00fb2594(psVar41,0x50,0x288);
    func_0x00720d10(psVar41,psVar23,psVar56);
    *(int *)((long)ppsVar7 + -0x294) = auVar113._8_4_;
    *(int *)((long)ppsVar7 + -0x290) = (int)psVar53;
    unaff_d8 = 0x100000001;
    *(undefined8 *)((long)ppsVar7 + -0x28c) = 0x100000001;
    func_0x00fc1fd0(psVar41);
    *(undefined8 *)(*(long *)((long)ppsVar7 + -600) + 8) = 0x100000001;
    psVar50 = (segment_command *)&__ZL20proxy_luma_quant_tbl;
    psVar56 = (segment_command *)0x0;
    psVar35 = (segment_command *)0x0;
    psVar33 = psVar34;
    func_0x00fc1c48(psVar41,0);
    *(undefined4 *)((long)ppsVar7 + -0x188) = 0;
    *(undefined4 *)((long)ppsVar7 + -0x198) = 1;
    func_0x00f9f004(psVar41);
    if (0 < (int)psVar53) {
      uVar19 = (ulong)psVar53 & 0xffffffff;
      psVar56 = (segment_command *)(long)(int)psVar30;
      psVar53 = (segment_command *)((long)ppsVar7 + -0x300);
      psVar34 = (segment_command *)((long)&MACH_HEADER.magic + 1);
      psVar29 = auVar113._0_8_;
      do {
        *(segment_command **)((long)ppsVar7 + -0x470) = psVar29;
        psVar50 = (segment_command *)((long)&MACH_HEADER.magic + 1);
        iVar12 = func_0x00f9f0ac(psVar53,(undefined1 *)((long)ppsVar7 + -0x470));
        psVar30 = (segment_command *)((long)ppsVar7 + -0x470);
        if (iVar12 != 1) goto LAB_01535fbc;
        psVar29 = (segment_command *)
                  ((long)psVar56->segname + (long)((long)psVar29->segname + -0x10));
        uVar19 = uVar19 - 1;
        psVar30 = (segment_command *)((long)ppsVar7 + -0x470);
      } while (uVar19 != 0);
    }
    func_0x00fb2730((undefined1 *)((long)ppsVar7 + -0x300));
    psVar52 = (segment_command *)
              (ulong)(uint)(*(int *)(*(long *)((long)ppsVar7 + -0x2d8) + 0x30) -
                           *(int *)(*(long *)((long)ppsVar7 + -0x2d8) + 8));
  }
  func_0x00fb26dc((undefined1 *)((long)ppsVar7 + -0x300));
  if (*(long *)PTR____stack_chk_guard_01d15188 == *(long *)((long)ppsVar7 + -0x78)) {
    return psVar52;
  }
  psVar21 = (segment_command *)___stack_chk_fail();
  puVar9 = (undefined1 *)((long)ppsVar7 + -0x580);
  *(segment_command **)((long)ppsVar7 + -0x4a0) = param_6;
  *(segment_command **)((long)ppsVar7 + -0x498) = unaff_x27;
  *(segment_command **)((long)ppsVar7 + -0x490) = psVar53;
  *(segment_command **)((long)ppsVar7 + -0x488) = psVar52;
  *(undefined1 **)((long)ppsVar7 + -0x480) = (undefined1 *)((long)ppsVar7 + -0x10);
  *(undefined8 *)((long)ppsVar7 + -0x478) = 0x15360fc;
  puVar61 = (undefined1 *)((long)ppsVar7 + -0x480);
  *(undefined8 *)((long)ppsVar7 + -0x4a8) = *(undefined8 *)PTR____stack_chk_guard_01d15188;
  psVar52 = (segment_command *)((long)ppsVar7 + -0x570);
  (**(code **)(*(long *)psVar21 + 0x18))(psVar21,(undefined1 *)((long)ppsVar7 + -0x570));
  *(segment_command **)((long)ppsVar7 + -0x580) = psVar52;
  func_0x00574408("Fatal proxy error (%s)");
  uVar18 = 0x1536158;
  auVar114 = _longjmp(*(long *)psVar21 + 0xa8,1);
  unaff_x22 = psVar34;
  param_5 = (char *)psVar29;
  psVar53 = psVar23;
  do {
    lVar42 = auVar114._8_8_;
    *(segment_command **)(puVar9 + -0x60) = param_6;
    *(segment_command **)(puVar9 + -0x58) = unaff_x27;
    *(segment_command **)(puVar9 + -0x50) = psVar41;
    *(segment_command **)(puVar9 + -0x48) = psVar53;
    *(char **)(puVar9 + -0x40) = param_5;
    *(segment_command **)(puVar9 + -0x38) = psVar56;
    *(segment_command **)(puVar9 + -0x30) = unaff_x22;
    *(segment_command **)(puVar9 + -0x28) = psVar30;
    *(segment_command **)(puVar9 + -0x20) = psVar52;
    *(segment_command **)(puVar9 + -0x18) = psVar21;
    *(undefined1 **)(puVar9 + -0x10) = puVar61;
    *(undefined8 *)(puVar9 + -8) = uVar18;
    *(undefined8 *)(puVar9 + -0x68) = *(undefined8 *)PTR____stack_chk_guard_01d15188;
    psVar53 = (segment_command *)(puVar9 + -0x460);
    psVar30 = psVar50;
    psVar23 = psVar33;
    psVar34 = psVar35;
    unaff_x23 = psVar37;
    puVar20 = (undefined8 *)func_0x00fc9cf0(psVar53);
    iVar62 = (int)psVar30;
    *(undefined8 **)(puVar9 + -0x2f8) = puVar20;
    *puVar20 = 0x15360fc;
    puVar20[2] = 0x1536334;
    iVar12 = _setjmp(puVar9 + -0x3b8);
    uVar32 = SUB84(psVar23,0);
    if (iVar12 == 1) goto LAB_015361d8;
    psVar53 = (segment_command *)(puVar9 + -0x2f8);
    func_0x00fc3460(psVar53,0x50,0x290);
    psVar30 = psVar37;
    func_0x00720ea8(psVar53,psVar35);
    iVar62 = (int)psVar30;
    iVar12 = func_0x00fc3598(psVar53,1);
    uVar32 = SUB84(psVar23,0);
    psVar30 = (segment_command *)0xffffffff;
    if ((((iVar12 == 1) && (*(int *)(puVar9 + -0x2c0) == 1)) &&
        (*(int *)(puVar9 + -0x2c8) == auVar114._8_4_)) &&
       (*(int *)(puVar9 + -0x2c4) == (int)psVar50)) {
      *(undefined4 *)(puVar9 + -0x298) = 0;
      func_0x00fa2bac(puVar9 + -0x2f8);
      uVar32 = SUB84(psVar23,0);
      if ((int)psVar50 < 1) {
LAB_015362d8:
        func_0x00fc38c0(puVar9 + -0x2f8);
        psVar30 = (segment_command *)0x0;
      }
      else {
        *(long *)(puVar9 + -0x468) = auVar114._0_8_;
        uVar18 = 1;
        iVar12 = func_0x00fa2df0(puVar9 + -0x2f8,puVar9 + -0x468);
        iVar62 = (int)uVar18;
        uVar32 = SUB84(psVar23,0);
        if (iVar12 == 1) {
          lVar42 = (long)(int)psVar33;
          psVar37 = (segment_command *)((ulong)psVar50 & 0xffffffff);
          psVar41 = (segment_command *)(auVar114._0_8_ + lVar42);
          psVar35 = (segment_command *)((long)&psVar37[-1].flags + 3);
          psVar50 = (segment_command *)(puVar9 + -0x468);
          psVar33 = (segment_command *)((long)&MACH_HEADER.magic + 1);
          psVar53 = (segment_command *)0x0;
          do {
            iVar62 = (int)uVar18;
            uVar32 = SUB84(psVar23,0);
            if (psVar35 == psVar53) goto LAB_015362d8;
            *(segment_command **)(puVar9 + -0x468) = psVar41;
            uVar18 = 1;
            iVar12 = func_0x00fa2df0(puVar9 + -0x2f8,psVar50);
            iVar62 = (int)uVar18;
            uVar32 = SUB84(psVar23,0);
            psVar41 = (segment_command *)((long)psVar41->segname + lVar42 + -8);
            psVar53 = (segment_command *)((long)&psVar53->cmd + 1);
          } while (iVar12 == 1);
          if (psVar37 <= psVar53) goto LAB_015362d8;
        }
LAB_015361d8:
        psVar30 = (segment_command *)0xffffffff;
      }
    }
    func_0x00fb26dc(puVar9 + -0x2f8);
    if (*(long *)PTR____stack_chk_guard_01d15188 == *(long *)(puVar9 + -0x68)) {
      return psVar30;
    }
    plVar22 = (long *)___stack_chk_fail();
    *(segment_command **)(puVar9 + -0x490) = psVar50;
    *(segment_command **)(puVar9 + -0x488) = psVar30;
    *(undefined1 **)(puVar9 + -0x480) = puVar9 + -0x10;
    *(undefined8 *)(puVar9 + -0x478) = 0x1536334;
    *(undefined8 *)(puVar9 + -0x498) = *(undefined8 *)PTR____stack_chk_guard_01d15188;
    (**(code **)(*plVar22 + 0x18))(plVar22,puVar9 + -0x560);
    *(undefined1 **)(puVar9 + -0x570) = puVar9 + -0x560;
    psVar30 = (segment_command *)func_0x00574408("Fatal proxy error (%s)");
    if (*(long *)PTR____stack_chk_guard_01d15188 == *(long *)(puVar9 + -0x498)) {
      return psVar30;
    }
    auVar112 = ___stack_chk_fail();
    iVar67 = auVar112._8_4_;
    *(undefined8 *)(puVar9 + -0x5f0) = unaff_d11;
    *(undefined8 *)(puVar9 + -0x5e8) = unaff_d10;
    *(undefined8 *)(puVar9 + -0x5e0) = unaff_d9;
    *(undefined8 *)(puVar9 + -0x5d8) = unaff_d8;
    *(segment_command **)(puVar9 + -0x5d0) = param_6;
    *(segment_command **)(puVar9 + -0x5c8) = unaff_x27;
    *(segment_command **)(puVar9 + -0x5c0) = psVar41;
    *(segment_command **)(puVar9 + -0x5b8) = psVar53;
    *(segment_command **)(puVar9 + -0x5b0) = psVar35;
    *(segment_command **)(puVar9 + -0x5a8) = psVar37;
    *(long *)(puVar9 + -0x5a0) = lVar42;
    *(segment_command **)(puVar9 + -0x598) = psVar33;
    *(segment_command **)(puVar9 + -0x590) = psVar50;
    *(undefined1 **)(puVar9 + -0x588) = puVar9 + -0x560;
    *(undefined1 **)(puVar9 + -0x580) = puVar9 + -0x480;
    *(undefined8 *)(puVar9 + -0x578) = 0x15363a4;
    puVar61 = puVar9 + -0x580;
    ppsVar7 = (segment_command **)(puVar9 + -0x780);
    *(undefined4 *)(puVar9 + -0x75c) = uVar32;
    *(long *)(puVar9 + -0x768) = auVar112._0_8_;
    uVar38 = 0;
    iVar12 = 0;
    uVar63 = iVar67 / 0x1f0;
    uVar13 = iVar62 / 0x1f0;
    if ((int)uVar63 < 2) {
      uVar63 = 1;
    }
    if (3 < uVar63) {
      uVar63 = 4;
    }
    if ((int)uVar13 < 2) {
      uVar13 = 1;
    }
    *(int *)(puVar9 + -0x760) = iVar67;
    *(uint *)(puVar9 + -0x750) = uVar63;
    *(int *)(puVar9 + -0x74c) = iVar62;
    iVar62 = 0;
    if (uVar63 != 0) {
      iVar62 = iVar67 / (int)uVar63;
    }
    uVar63 = iVar62 + 7;
    uVar19 = (ulong)uVar63;
    *(undefined8 *)(puVar9 + -0x600) = *(undefined8 *)PTR____stack_chk_guard_01d15188;
    *(segment_command **)(puVar9 + -0x758) = psVar34;
    iVar62 = (int)psVar34;
    psVar30 = unaff_x23;
    psVar21 = param_7;
    do {
      uVar48 = 0;
      do {
        if ((int)uVar48 == 0 && (int)uVar38 == 0) {
          iVar12 = iVar12 + 0xe;
        }
        else {
          auVar115 = SEXT816((long)((ulong)*(uint *)(&__ZL20proxy_luma_quant_tbl +
                                                    (uVar48 + uVar38 * 8) * 4) * (long)iVar62 + 0x32
                                   )) * ZEXT816(0xa3d70a3d70a3d70b);
          iVar67 = (int)(auVar115._8_8_ >> 6) - (auVar115._12_4_ >> 0x1f);
          if (0x7ffe < iVar67) {
            iVar67 = 0x7fff;
          }
          if (iVar67 < 2) {
            iVar67 = 1;
          }
          iVar68 = 0;
          if (iVar67 != 0) {
            iVar68 = *(int *)(&__ZZN5Proxy17jpeg_compress_capEiiiE5range +
                             (uVar38 & 3 | (uVar48 & 3) << 2) * 4) / iVar67;
          }
          psVar30 = (segment_command *)((long)&MACH_HEADER.magic + 1);
          do {
            iVar12 = iVar12 + 1;
            uVar36 = (uint)psVar30;
            uVar14 = 1 << (ulong)(uVar36 & 0x1f);
            psVar21 = (segment_command *)(ulong)uVar14;
            psVar30 = (segment_command *)(ulong)(uVar36 + 1);
          } while ((int)uVar14 < iVar68);
          uVar14 = 1;
          do {
            uVar2 = 1 << (ulong)(uVar14 & 0x1f);
            psVar34 = (segment_command *)(ulong)uVar2;
            uVar14 = uVar14 + 1;
            iVar12 = iVar12 + 1;
          } while ((int)uVar2 < (int)uVar36);
        }
        uVar48 = uVar48 + 1;
      } while (uVar48 != 8);
      uVar38 = uVar38 + 1;
    } while (uVar38 != 8);
    if (3 < uVar13) {
      uVar13 = 4;
    }
    iVar62 = 0;
    if (uVar13 != 0) {
      iVar62 = *(int *)(puVar9 + -0x74c) / (int)uVar13;
    }
    uVar14 = iVar62 + 7;
    unaff_x21 = (segment_command *)(ulong)uVar14;
    param_5 = (char *)(ulong)(uVar13 * *(int *)(puVar9 + -0x750));
    uVar2 = uVar63 | 7;
    uVar36 = uVar2 + 7;
    if (-1 < (int)uVar2) {
      uVar36 = uVar2;
    }
    uVar3 = uVar14 | 7;
    uVar2 = uVar3 + 7;
    if (-1 < (int)uVar3) {
      uVar2 = uVar3;
    }
    uVar2 = ((int)uVar2 >> 3) * ((int)uVar36 >> 3) * iVar12;
    uVar36 = uVar2 + 7;
    if (-1 < (int)uVar2) {
      uVar36 = uVar2;
    }
    iVar12 = (uVar36 & 0xfffffff8) + ((int)uVar36 >> 3);
    iVar62 = iVar12 + 7;
    if (-1 < iVar12) {
      iVar62 = iVar12;
    }
    uVar36 = ((int)uVar36 >> 3) + (iVar62 >> 3) + 0x800;
    psVar56 = (segment_command *)(ulong)uVar36;
    psVar23 = (segment_command *)_malloc((long)(int)(uVar36 * uVar13 * *(int *)(puVar9 + -0x750)));
    unaff_x27 = psVar56;
    if (psVar23 != (segment_command *)0x0) break;
    unaff_x22 = (segment_command *)0xffffffff;
    if (*(long *)PTR____stack_chk_guard_01d15188 == *(long *)(puVar9 + -0x600)) {
      return (segment_command *)0xffffffff;
    }
    uVar18 = 0x1537114;
    auVar115 = ___stack_chk_fail();
    ppsVar8 = (segment_command **)(puVar9 + -0x780);
    param_7 = psVar21;
__ZN5Proxy13tjpg_plan_addEP22tjpg_plan_decompress_tPhiiiPKvi:
    auVar75._8_8_ = psVar41;
    auVar75._0_8_ = uVar19;
    psVar21 = auVar115._0_8_;
    ppsVar10 = (segment_command **)((long)ppsVar8 + -0x1c0);
    *(segment_command **)((long)ppsVar8 + -0x60) = param_6;
    *(segment_command **)((long)ppsVar8 + -0x58) = unaff_x27;
    *(segment_command **)((long)ppsVar8 + -0x50) = psVar41;
    *(segment_command **)((long)ppsVar8 + -0x48) = psVar53;
    *(char **)((long)ppsVar8 + -0x40) = param_5;
    *(segment_command **)((long)ppsVar8 + -0x38) = unaff_x23;
    *(segment_command **)((long)ppsVar8 + -0x30) = unaff_x22;
    *(segment_command **)((long)ppsVar8 + -0x28) = unaff_x21;
    *(segment_command **)((long)ppsVar8 + -0x20) = psVar50;
    *(ulong *)((long)ppsVar8 + -0x18) = uVar19;
    *(undefined1 **)((long)ppsVar8 + -0x10) = puVar61;
    *(undefined8 *)((long)ppsVar8 + -8) = uVar18;
    puVar61 = (undefined1 *)((long)ppsVar8 + -0x10);
    *(undefined8 *)((long)ppsVar8 + -0x70) = *(undefined8 *)PTR____stack_chk_guard_01d15188;
    psVar23 = psVar21;
    if (-1 < (int)psVar21->cmd) {
      param_5 = (char *)0x0;
      unaff_x23 = (segment_command *)0x0;
      do {
        bVar1 = *(byte *)((long)((segment_command *)param_5)->segname +
                         (long)((long)psVar30->segname + -0x10));
        uVar63 = bVar1 & 0x7f | (int)unaff_x23 << 7;
        unaff_x23 = (segment_command *)(ulong)uVar63;
        param_5 = (char *)((long)&((segment_command *)param_5)->cmd + 1);
      } while ((char)bVar1 < '\0');
      psVar50 = psVar30;
      psVar53 = psVar34;
      auVar75 = auVar115;
      if (uVar63 - 0x11 < 0xfffffff0) {
        psVar23 = (segment_command *)func_0x00574408("tjpg_plan_add: bad tile specification.");
        psVar21->cmd = 0xffffffff;
      }
      else {
        psVar56 = (segment_command *)0x0;
        do {
          lVar42 = 0;
          uVar13 = 0;
          iVar12 = (int)param_5;
          uVar14 = iVar12 + 4;
          do {
            uVar36 = uVar14;
            bVar1 = *(byte *)((long)psVar30->segname + lVar42 + iVar12 + -8);
            uVar13 = bVar1 & 0x7f | uVar13 << 7;
            lVar42 = lVar42 + 1;
            uVar14 = uVar36 + 1;
          } while ((char)bVar1 < '\0');
          lVar24 = 0;
          uVar14 = 0;
          *(uint *)((long)ppsVar8 + (long)psVar56 * 4 + -0xb0) = uVar13;
          lVar42 = (long)iVar12 + (long)(int)lVar42;
          do {
            uVar13 = uVar36;
            bVar1 = *(byte *)((long)psVar30->segname + lVar24 + lVar42 + -8);
            uVar14 = bVar1 & 0x7f | uVar14 << 7;
            lVar24 = lVar24 + 1;
            uVar36 = uVar13 + 1;
          } while ((char)bVar1 < '\0');
          lVar49 = 0;
          uVar36 = 0;
          *(uint *)((long)ppsVar8 + (long)psVar56 * 4 + -0xf0) = uVar14;
          iVar12 = (int)lVar42 + (int)lVar24;
          do {
            uVar14 = uVar13;
            bVar1 = *(byte *)((long)psVar30->segname + lVar49 + iVar12 + -8);
            uVar36 = bVar1 & 0x7f | uVar36 << 7;
            lVar49 = lVar49 + 1;
            uVar13 = uVar14 + 1;
          } while ((char)bVar1 < '\0');
          lVar42 = 0;
          psVar23 = (segment_command *)0x0;
          *(uint *)((long)ppsVar8 + (long)psVar56 * 4 + -0x130) = uVar36;
          do {
            uVar13 = uVar14;
            param_5 = (char *)(ulong)uVar13;
            bVar1 = *(byte *)((long)psVar30->segname + lVar42 + (iVar12 + (int)lVar49) + -8);
            uVar36 = bVar1 & 0x7f | (int)psVar23 << 7;
            psVar23 = (segment_command *)(ulong)uVar36;
            lVar42 = lVar42 + 1;
            uVar14 = uVar13 + 1;
          } while ((char)bVar1 < '\0');
          uVar14 = 0;
          *(uint *)((long)ppsVar8 + (long)psVar56 * 4 + -0x170) = uVar36;
          pbVar44 = (byte *)((long)psVar30->segname + (long)(int)uVar13 + -8);
          do {
            bVar1 = *pbVar44;
            uVar14 = bVar1 & 0x7f | uVar14 << 7;
            param_5 = (char *)(ulong)((int)param_5 + 1);
            pbVar44 = pbVar44 + 1;
          } while ((char)bVar1 < '\0');
          *(uint *)((long)ppsVar8 + (long)psVar56 * 4 + -0x1b0) = uVar14;
          psVar56 = (segment_command *)((long)&psVar56->cmd + 1);
        } while (psVar56 != unaff_x23);
        if (uVar63 != 0) {
          *(segment_command **)((long)ppsVar8 + -0x1c0) = psVar21;
          puVar43 = (undefined4 *)((long)ppsVar8 + -0x170);
          piVar40 = (int *)((long)ppsVar8 + -0xf0);
          puVar55 = (uint *)((long)ppsVar8 + -0xb0);
          puVar57 = (uint *)((long)ppsVar8 + -0x1b0);
          puVar60 = (undefined4 *)((long)ppsVar8 + -0x130);
          do {
            lVar42 = (long)(int)psVar21->cmdsize;
            psVar21->cmdsize = psVar21->cmdsize + 1;
            *(long *)(psVar21->segname + lVar42 * 8 + 8) =
                 (long)psVar30->segname + (long)(int)param_5 + -8;
            unaff_x27 = (segment_command *)(puVar57 + 1);
            uVar63 = *puVar57;
            unaff_x21 = (segment_command *)(ulong)uVar63;
            *(uint *)(psVar21[5].segname + lVar42 * 4 + 0x20) = uVar63;
            unaff_x22 = (segment_command *)(puVar55 + 1);
            *(ulong *)(psVar21[2].segname + lVar42 * 8 + -8) =
                 auVar115._8_8_ + (ulong)(uint)(*piVar40 * (int)psVar34) + (ulong)*puVar55;
            *(int *)(psVar21[6].segname + lVar42 * 4 + 0x18) = (int)psVar34;
            param_6 = (segment_command *)(puVar60 + 1);
            *(undefined4 *)(psVar21[3].segname + lVar42 * 4 + 0x30) = *puVar60;
            auVar75._8_8_ = auVar115._8_8_;
            auVar75._0_8_ = puVar43 + 1;
            *(undefined4 *)(psVar21[4].segname + lVar42 * 4 + 0x28) = *puVar43;
            if (0xf < (int)psVar21->cmdsize) {
              *(int **)((long)ppsVar8 + -0x1b8) = piVar40 + 1;
              uVar18 = 0x1537354;
              goto __ZN5Proxy13tjpg_plan_runEP22tjpg_plan_decompress_t;
            }
            param_5 = (char *)(ulong)(uVar63 + (int)param_5);
            unaff_x23 = (segment_command *)((long)&unaff_x23[-1].flags + 3);
            puVar43 = puVar43 + 1;
            piVar40 = piVar40 + 1;
            puVar55 = (uint *)unaff_x22;
            puVar57 = (uint *)unaff_x27;
            puVar60 = (undefined4 *)param_6;
            auVar75 = auVar115;
          } while (unaff_x23 != (segment_command *)0x0);
        }
      }
    }
    if (*(long *)PTR____stack_chk_guard_01d15188 == *(long *)((long)ppsVar8 + -0x70)) {
      return psVar23;
    }
    uVar18 = 0x15373a0;
    psVar21 = (segment_command *)___stack_chk_fail();
    ppsVar10 = (segment_command **)((long)ppsVar8 + -0x1c0);
__ZN5Proxy13tjpg_plan_runEP22tjpg_plan_decompress_t:
    psVar41 = auVar75._8_8_;
    puVar9 = (undefined1 *)((long)ppsVar10 + -0x110);
    *(segment_command **)((long)ppsVar10 + -0x60) = param_6;
    *(segment_command **)((long)ppsVar10 + -0x58) = unaff_x27;
    *(segment_command **)((long)ppsVar10 + -0x50) = psVar41;
    *(segment_command **)((long)ppsVar10 + -0x48) = psVar53;
    *(char **)((long)ppsVar10 + -0x40) = param_5;
    *(segment_command **)((long)ppsVar10 + -0x38) = unaff_x23;
    *(segment_command **)((long)ppsVar10 + -0x30) = unaff_x22;
    *(segment_command **)((long)ppsVar10 + -0x28) = unaff_x21;
    *(segment_command **)((long)ppsVar10 + -0x20) = psVar50;
    *(long *)((long)ppsVar10 + -0x18) = auVar75._0_8_;
    *(undefined1 **)((long)ppsVar10 + -0x10) = puVar61;
    *(undefined8 *)((long)ppsVar10 + -8) = uVar18;
    puVar61 = (undefined1 *)((long)ppsVar10 + -0x10);
    *(undefined8 *)((long)ppsVar10 + -0x70) = *(undefined8 *)PTR____stack_chk_guard_01d15188;
    psVar30 = (segment_command *)(ulong)psVar21->cmd;
    if ((int)psVar21->cmd < 0) goto LAB_0153773c;
    uVar63 = psVar21->cmdsize;
    psVar56 = (segment_command *)(ulong)uVar63;
    if ((int)uVar63 < 1) {
      psVar30 = (segment_command *)0x0;
      goto LAB_0153773c;
    }
    if ((__DEBUG_PROXY_THREADSIZE < 1 || uVar63 == 1) || psVar21->segname[0] == '\0') {
      *(undefined1 *)((long)ppsVar10 + -0xe1) = 0;
    }
    else {
      lVar42 = 0;
      iVar12 = 0;
      do {
        if ((__DEBUG_PROXY_THREADSIZE <= *(int *)(psVar21[3].segname + lVar42 + 0x30)) ||
           (__DEBUG_PROXY_THREADSIZE <= *(int *)(psVar21[4].segname + lVar42 + 0x28))) {
          iVar12 = iVar12 + 1;
        }
        lVar42 = lVar42 + 4;
      } while ((long)psVar56 * 4 - lVar42 != 0);
      *(undefined1 *)((long)ppsVar10 + -0xe1) = 0;
      if (1 < iVar12) {
        *(undefined1 **)((long)ppsVar10 + -0xf8) = (undefined1 *)((long)ppsVar10 + -0xe1);
        *(segment_command **)((long)ppsVar10 + -0xf0) = psVar21;
        *(undefined8 *)((long)ppsVar10 + -0xc0) = 0x32aaaba7;
        *(undefined8 *)((long)ppsVar10 + -0xb0) = 0;
        *(undefined8 *)((long)ppsVar10 + -0xb8) = 0;
        *(undefined8 *)((long)ppsVar10 + -0xa0) = 0;
        *(undefined8 *)((long)ppsVar10 + -0xa8) = 0;
        *(undefined8 *)((long)ppsVar10 + -0x90) = 0;
        *(undefined8 *)((long)ppsVar10 + -0x98) = 0;
        *(undefined8 *)((long)ppsVar10 + -0x80) = 0;
        *(undefined8 *)((long)ppsVar10 + -0x88) = 0;
        *(undefined1 *)((long)ppsVar10 + -0x78) = 0;
        uVar14 = __ZNSt3__16thread20hardware_concurrencyEv();
        uVar13 = uVar14;
        if (uVar63 <= uVar14) {
          uVar13 = uVar63;
        }
        *(undefined8 *)((long)ppsVar10 + -0xe0) = 0;
        *(undefined8 *)((long)ppsVar10 + -0xd8) = 0;
        *(undefined8 *)((long)ppsVar10 + -0xd0) = 0;
        func_0x0019952c((undefined1 *)((long)ppsVar10 + -0xe0),uVar13);
        if (uVar13 == 0) goto LAB_01537774;
        uVar36 = 0;
        uVar2 = 0;
        if (uVar14 != 0) {
          uVar2 = uVar63 / uVar14;
        }
        *(uint *)((long)ppsVar10 + -0xfc) = uVar2;
        *(uint *)((long)ppsVar10 + -0x100) = uVar63 - uVar2 * uVar14;
        plVar22 = *(long **)((long)ppsVar10 + -0xd8);
        goto LAB_01537534;
      }
    }
    psVar52 = psVar21 + 2;
    psVar30 = (segment_command *)&psVar21[6].vmsize;
    psVar35 = *(segment_command **)(psVar21->segname + 8);
    psVar37 = (segment_command *)(ulong)(uint)psVar21[5].fileoff;
    uVar15 = psVar52->cmd;
    uVar28 = psVar52->cmdsize;
    auVar114._4_4_ = uVar28;
    auVar114._0_4_ = uVar15;
    psVar33 = (segment_command *)(ulong)(uint)*(qword *)psVar30;
    auVar114._8_4_ = psVar21[3].maxprot;
    auVar114._12_4_ = 0;
    psVar50 = (segment_command *)(ulong)(uint)psVar21[4].filesize;
    uVar18 = 0x15376f0;
  } while( true );
  *(segment_command **)(puVar9 + -0x780) = unaff_x23;
  *(int *)(puVar9 + -0x774) = (int)param_7;
  param_3 = 0;
  uVar63 = uVar63 & 0xfffffff8;
  unaff_x22 = (segment_command *)(ulong)uVar63;
  uVar14 = uVar14 & 0xfffffff8;
  unaff_x23 = (segment_command *)(ulong)uVar14;
  *(long *)(puVar9 + -0x748) = (long)(int)uVar36;
  *(segment_command **)(puVar9 + -0x770) = psVar23;
  param_1 = (long *)0x0;
  param_4 = (segment_command *)0x0;
  psVar30 = (segment_command *)(ulong)*(uint *)(puVar9 + -0x75c);
  if ((int)*(uint *)(puVar9 + -0x760) <= (int)uVar63) {
    uVar63 = *(uint *)(puVar9 + -0x760);
  }
  if ((int)*(uint *)(puVar9 + -0x74c) <= (int)uVar14) {
    uVar14 = *(uint *)(puVar9 + -0x74c);
  }
  uVar19 = (ulong)uVar63;
  auVar113._8_4_ = uVar63;
  auVar113._0_8_ = *(undefined8 *)(puVar9 + -0x768);
  auVar113._12_4_ = 0;
  psVar53 = (segment_command *)(ulong)uVar14;
  psVar34 = *(segment_command **)(puVar9 + -0x758);
  uVar18 = 0x1536654;
  unaff_x21 = psVar53;
  param_6 = psVar23;
  goto __ZN5Proxy13jpeg_compressEPhiiiiPvi;
code_r0x015376a8:
  if (plVar26 != (long *)0x0) {
    lVar42 = 5;
LAB_01537680:
    (**(code **)(*plVar26 + lVar42 * 8))();
  }
  goto joined_r0x01537670;
LAB_01537534:
  do {
    if (plVar22 < *(long **)((long)ppsVar10 + -0xd0)) {
      plVar22[3] = 0;
      puVar20 = (undefined8 *)__Znwm(0x30);
      *puVar20 = &
                 PTR___ZNSt3__110__function6__funcIZN2P18Parallel7Details9ForStaticIiZN5Proxy13tjpg_plan_runEP22tjpg_plan_decompress_tE3__0EEvT_SA_DTmifL0pK0_fL0pK_ERKT0_EUliE_NS_9allocatorISF_EEFviEED1Ev_01ffcf68
      ;
      puVar20[1] = (undefined1 *)((long)ppsVar10 + -0xc0);
      puVar20[2] = (undefined1 *)((long)ppsVar10 + -0xf8);
      uVar32 = *(undefined4 *)((long)ppsVar10 + -0x100);
      *(uint *)(puVar20 + 3) = uVar36;
      *(undefined4 *)((long)puVar20 + 0x1c) = uVar32;
      *(undefined4 *)(puVar20 + 4) = 0;
      *(uint *)((long)puVar20 + 0x24) = uVar63;
      uVar32 = *(undefined4 *)((long)ppsVar10 + -0xfc);
      *(undefined4 *)(puVar20 + 5) = 1;
      *(undefined4 *)((long)puVar20 + 0x2c) = uVar32;
      plVar27 = plVar22 + 4;
      plVar22[3] = (long)puVar20;
    }
    else {
      plVar58 = *(long **)((long)ppsVar10 + -0xe0);
      lVar42 = (long)plVar22 - (long)plVar58 >> 5;
      uVar19 = lVar42 + 1;
      if (uVar19 >> 0x3b != 0) goto LAB_01537818;
      uVar48 = (long)*(long **)((long)ppsVar10 + -0xd0) - (long)plVar58;
      uVar38 = (long)uVar48 >> 4;
      if (uVar38 <= uVar19) {
        uVar38 = uVar19;
      }
      if (0x7fffffffffffffdf < uVar48) {
        uVar38 = 0x7ffffffffffffff;
      }
      if (uVar38 == 0) {
        lVar24 = 0;
      }
      else {
        if (uVar38 >> 0x3b != 0) {
          func_0x00108f70();
          goto LAB_0153784c;
        }
        lVar24 = __Znwm(uVar38 << 5);
      }
      lVar42 = lVar24 + lVar42 * 0x20;
      *(undefined8 *)(lVar42 + 0x18) = 0;
      puVar20 = (undefined8 *)__Znwm(0x30);
      *puVar20 = &
                 PTR___ZNSt3__110__function6__funcIZN2P18Parallel7Details9ForStaticIiZN5Proxy13tjpg_plan_runEP22tjpg_plan_decompress_tE3__0EEvT_SA_DTmifL0pK0_fL0pK_ERKT0_EUliE_NS_9allocatorISF_EEFviEED1Ev_01ffcf68
      ;
      puVar20[1] = (undefined1 *)((long)ppsVar10 + -0xc0);
      lVar24 = lVar24 + uVar38 * 0x20;
      puVar20[2] = (undefined1 *)((long)ppsVar10 + -0xf8);
      uVar32 = *(undefined4 *)((long)ppsVar10 + -0x100);
      *(uint *)(puVar20 + 3) = uVar36;
      *(undefined4 *)((long)puVar20 + 0x1c) = uVar32;
      *(undefined4 *)(puVar20 + 4) = 0;
      *(uint *)((long)puVar20 + 0x24) = uVar63;
      uVar32 = *(undefined4 *)((long)ppsVar10 + -0xfc);
      *(undefined4 *)(puVar20 + 5) = 1;
      *(undefined4 *)((long)puVar20 + 0x2c) = uVar32;
      plVar27 = (long *)(lVar42 + 0x20);
      *(undefined8 **)(lVar42 + 0x18) = puVar20;
      if (plVar22 == plVar58) {
        *(long *)((long)ppsVar10 + -0xe0) = lVar42;
        *(long **)((long)ppsVar10 + -0xd8) = plVar27;
        *(long *)((long)ppsVar10 + -0xd0) = lVar24;
      }
      else {
        *(long *)((long)ppsVar10 + -0x108) = lVar24;
        lVar24 = 0;
        plVar26 = plVar22;
        do {
          plVar54 = (long *)(lVar42 + lVar24);
          plVar39 = *(long **)((long)plVar22 + lVar24 + -8);
          if (plVar39 == (long *)0x0) {
LAB_01537600:
            plVar54[-1] = 0;
          }
          else {
            plVar25 = (long *)((long)plVar22 + lVar24 + -0x20);
            if (plVar25 != plVar39) {
              plVar54[-1] = (long)plVar39;
              plVar54 = plVar26;
              goto LAB_01537600;
            }
            plVar54[-1] = (long)(plVar54 + -4);
            (**(code **)(*plVar25 + 0x18))();
          }
          plVar26 = plVar26 + -4;
          lVar24 = lVar24 + -0x20;
        } while ((long *)((long)plVar22 + lVar24) != plVar58);
        plVar22 = *(long **)((long)ppsVar10 + -0xe0);
        plVar58 = *(long **)((long)ppsVar10 + -0xd8);
        *(long *)((long)ppsVar10 + -0xe0) = lVar42 + lVar24;
        *(long **)((long)ppsVar10 + -0xd8) = plVar27;
        *(undefined8 *)((long)ppsVar10 + -0xd0) = *(undefined8 *)((long)ppsVar10 + -0x108);
joined_r0x01537670:
        if (plVar58 != plVar22) {
          plVar54 = plVar58 + -4;
          plVar26 = (long *)plVar58[-1];
          plVar58 = plVar54;
          if (plVar54 != plVar26) goto code_r0x015376a8;
          lVar42 = 4;
          plVar26 = plVar54;
          goto LAB_01537680;
        }
      }
      if (plVar22 != (long *)0x0) {
        __ZdlPv(plVar22);
      }
    }
    *(long **)((long)ppsVar10 + -0xd8) = plVar27;
    uVar36 = uVar36 + 1;
    plVar22 = plVar27;
  } while (uVar13 != uVar36);
LAB_01537774:
  func_0x00728824((undefined1 *)((long)ppsVar10 + -0xe0));
  if ((*(byte *)((long)ppsVar10 + -0x78) & 1) == 0) {
    plVar22 = *(long **)((long)ppsVar10 + -0xe0);
    if (plVar22 != (long *)0x0) {
      plVar27 = plVar22;
      plVar58 = *(long **)((long)ppsVar10 + -0xd8);
      if (*(long **)((long)ppsVar10 + -0xd8) != plVar22) {
        do {
          plVar26 = plVar58 + -4;
          plVar27 = (long *)plVar58[-1];
          if (plVar26 == plVar27) {
            lVar42 = 4;
            plVar27 = plVar26;
LAB_015377b0:
            (**(code **)(*plVar27 + lVar42 * 8))();
          }
          else if (plVar27 != (long *)0x0) {
            lVar42 = 5;
            goto LAB_015377b0;
          }
          plVar58 = plVar26;
        } while (plVar26 != plVar22);
        plVar27 = *(long **)((long)ppsVar10 + -0xe0);
      }
      *(long **)((long)ppsVar10 + -0xd8) = plVar22;
      __ZdlPv(plVar27);
    }
    __ZNSt13exception_ptrD1Ev((undefined1 *)((long)ppsVar10 + -0x80));
    __ZNSt3__15mutexD1Ev((undefined1 *)((long)ppsVar10 + -0xc0));
    if ((*(byte *)((long)ppsVar10 + -0xe1) & 1) == 0) {
      psVar30 = (segment_command *)0x0;
      psVar21->cmdsize = 0;
    }
    else {
      psVar30 = (segment_command *)0xffffffff;
      psVar21->cmd = 0xffffffff;
    }
LAB_0153773c:
    if (*(long *)PTR____stack_chk_guard_01d15188 == *(long *)((long)ppsVar10 + -0x70)) {
      return psVar30;
    }
    ___stack_chk_fail(psVar30);
LAB_01537818:
    func_0x00108ee8((undefined1 *)((long)ppsVar10 + -0xe0));
  }
  else {
    __ZNSt3__15mutex4lockEv((undefined1 *)((long)ppsVar10 + -0xc0));
    __ZNSt13exception_ptrC1ERKS_
              ((undefined1 *)((long)ppsVar10 + -200),(undefined1 *)((long)ppsVar10 + -0x80));
    __ZSt17rethrow_exceptionSt13exception_ptr((undefined1 *)((long)ppsVar10 + -200));
  }
LAB_0153784c:
                    /* WARNING: Does not return */
  pcVar6 = (code *)SoftwareBreakpoint(1,0x1537850);
  (*pcVar6)();
}


/* __ZN5ProxyL14GetVersionListEv @ 015380bc */

/* WARNING: Type propagation algorithm not settling */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8 * __ZN5ProxyL14GetVersionListEv(void)

{
  int iVar1;
  undefined8 *puVar2;
  byte *pbVar3;
  undefined8 uStack_648;
  undefined4 uStack_640;
  undefined8 auStack_638 [2];
  char cStack_621;
  undefined8 uStack_620;
  undefined8 uStack_618;
  undefined4 uStack_610;
  undefined8 auStack_608 [2];
  char cStack_5f1;
  undefined8 uStack_5f0;
  undefined8 uStack_5e8;
  undefined4 uStack_5e0;
  undefined8 auStack_5d8 [2];
  char cStack_5c1;
  undefined8 uStack_5c0;
  undefined8 uStack_5b8;
  undefined4 uStack_5b0;
  undefined8 auStack_5a8 [2];
  char cStack_591;
  undefined8 uStack_590;
  undefined8 uStack_588;
  undefined4 uStack_580;
  undefined8 auStack_578 [2];
  char cStack_561;
  undefined8 uStack_560;
  undefined8 uStack_558;
  undefined4 uStack_550;
  undefined8 auStack_548 [2];
  char cStack_531;
  undefined8 uStack_530;
  undefined8 uStack_528;
  undefined4 uStack_520;
  undefined8 auStack_518 [2];
  char cStack_501;
  undefined8 uStack_500;
  undefined8 uStack_4f8;
  undefined4 uStack_4f0;
  undefined8 auStack_4e8 [2];
  char cStack_4d1;
  undefined8 uStack_4d0;
  undefined8 uStack_4c8;
  undefined4 uStack_4c0;
  undefined8 auStack_4b8 [2];
  char cStack_4a1;
  undefined8 uStack_4a0;
  undefined8 uStack_498;
  undefined4 uStack_490;
  undefined8 auStack_488 [2];
  char cStack_471;
  undefined8 uStack_470;
  undefined8 uStack_468;
  undefined4 uStack_460;
  undefined8 auStack_458 [2];
  char cStack_441;
  undefined8 uStack_440;
  undefined8 uStack_438;
  undefined4 uStack_430;
  undefined8 auStack_428 [2];
  char cStack_411;
  undefined8 uStack_410;
  undefined8 uStack_408;
  undefined4 uStack_400;
  undefined8 auStack_3f8 [2];
  char cStack_3e1;
  undefined8 uStack_3e0;
  undefined8 uStack_3d8;
  undefined4 uStack_3d0;
  undefined8 auStack_3c8 [2];
  char cStack_3b1;
  undefined8 uStack_3b0;
  undefined8 uStack_3a8;
  undefined4 uStack_3a0;
  undefined8 auStack_398 [2];
  char cStack_381;
  undefined8 uStack_380;
  undefined8 uStack_378;
  undefined4 uStack_370;
  undefined8 auStack_368 [2];
  char cStack_351;
  undefined8 uStack_350;
  undefined8 uStack_348;
  undefined4 uStack_340;
  undefined8 auStack_338 [2];
  char cStack_321;
  undefined8 uStack_320;
  undefined8 uStack_318;
  undefined4 uStack_310;
  undefined8 auStack_308 [2];
  char cStack_2f1;
  undefined8 uStack_2f0;
  undefined8 uStack_2e8;
  undefined4 uStack_2e0;
  undefined8 auStack_2d8 [2];
  char cStack_2c1;
  undefined8 uStack_2c0;
  undefined8 uStack_2b8;
  undefined4 uStack_2b0;
  undefined8 auStack_2a8 [2];
  char cStack_291;
  undefined8 uStack_290;
  undefined8 uStack_288;
  undefined4 uStack_280;
  undefined8 auStack_278 [2];
  char cStack_261;
  undefined8 uStack_260;
  undefined8 uStack_258;
  undefined4 uStack_250;
  undefined8 auStack_248 [2];
  char cStack_231;
  undefined8 uStack_230;
  undefined8 uStack_228;
  undefined4 uStack_220;
  undefined8 auStack_218 [2];
  char cStack_201;
  undefined8 uStack_200;
  undefined8 uStack_1f8;
  undefined4 uStack_1f0;
  undefined8 auStack_1e8 [2];
  char cStack_1d1;
  undefined8 uStack_1d0;
  undefined8 uStack_1c8;
  undefined4 uStack_1c0;
  undefined8 auStack_1b8 [2];
  char cStack_1a1;
  undefined8 uStack_1a0;
  undefined8 uStack_198;
  undefined4 uStack_190;
  undefined8 auStack_188 [2];
  char cStack_171;
  undefined8 uStack_170;
  undefined8 uStack_168;
  undefined4 uStack_160;
  undefined8 auStack_158 [2];
  char cStack_141;
  undefined8 uStack_140;
  undefined8 uStack_138;
  undefined4 uStack_130;
  undefined8 auStack_128 [2];
  char cStack_111;
  undefined **ppuStack_110;
  undefined8 uStack_108;
  undefined4 uStack_100;
  undefined8 auStack_f8 [2];
  char cStack_e1;
  undefined **ppuStack_e0;
  undefined8 uStack_d8;
  undefined4 uStack_d0;
  undefined8 auStack_c8 [2];
  char cStack_b1;
  undefined8 uStack_b0;
  undefined8 uStack_a8;
  undefined4 uStack_a0;
  undefined8 auStack_98 [2];
  char cStack_81;
  undefined8 uStack_80;
  undefined8 uStack_78;
  undefined4 uStack_70;
  undefined8 auStack_68 [2];
  char cStack_51;
  undefined **ppuStack_50;
  long lStack_48;
  byte *pbVar4;

  lStack_48 = *(long *)PTR____stack_chk_guard_01d15188;
  pbVar3 = (byte *)0x205ec80;
  pbVar4 = pbVar3;
  if (((bRam000000000205ec88 & 1) == 0) && (iVar1 = ___cxa_guard_acquire(0x205ec88), iVar1 != 0)) {
    puVar2 = (undefined8 *)__Znwm(0x18);
    uStack_648 = 0;
    uStack_640 = 0;
    func_0x001eb5a8(auStack_638,"Invalid");
    uStack_620 = 0;
    uStack_618 = _UNK_017da1f0;
    uStack_610 = 0;
    func_0x001eb5a8(auStack_608,"Legacy v1");
    uStack_5f0 = 0;
    uStack_5e8 = _UNK_01573008;
    uStack_5e0 = 0;
    func_0x001eb5a8(auStack_5d8,"Legacy v2");
    uStack_5c0 = 0;
    uStack_5b8 = _UNK_0189ed08;
    uStack_5b0 = 0;
    func_0x001eb5a8(auStack_5a8,"Legacy v3");
    uStack_590 = 0;
    uStack_588 = _UNK_0189b790;
    uStack_580 = 0;
    func_0x001eb5a8(auStack_578,"Legacy v4");
    uStack_560 = 0;
    uStack_558 = _UNK_01a818c8;
    uStack_550 = 0;
    func_0x001eb5a8(auStack_548,"Legacy v5");
    uStack_530 = 0;
    uStack_528 = _UNK_01812f20;
    uStack_520 = 0;
    func_0x001eb5a8(auStack_518,"Legacy v6");
    uStack_500 = 0;
    uStack_4f8 = _UNK_017daa20;
    uStack_4f0 = 0;
    func_0x001eb5a8(auStack_4e8,"Legacy v7");
    uStack_4d0 = 0;
    uStack_4c8 = _UNK_017e93b0;
    uStack_4c0 = 0;
    func_0x001eb5a8(auStack_4b8,"Legacy v8");
    uStack_4a0 = 0;
    uStack_498 = _UNK_017f4458;
    uStack_490 = 0;
    func_0x001eb5a8(auStack_488,"Legacy v9");
    uStack_470 = 0;
    uStack_468 = _UNK_01a9c390;
    uStack_460 = 0;
    func_0x001eb5a8(auStack_458,"Legacy v10");
    uStack_440 = 0;
    uStack_438 = _UNK_017f4450;
    uStack_430 = 0;
    func_0x001eb5a8(auStack_428,"Legacy v11");
    uStack_410 = 0;
    uStack_408 = _UNK_01a818d8;
    uStack_400 = 0;
    func_0x001eb5a8(auStack_3f8,"Legacy v12");
    uStack_3e0 = 0;
    uStack_3d8 = _UNK_01a9c398;
    uStack_3d0 = 0;
    func_0x001eb5a8(auStack_3c8,"Legacy v13");
    uStack_3b0 = 0;
    uStack_3a8 = _UNK_01866f60;
    uStack_3a0 = 0;
    func_0x001eb5a8(auStack_398,"Legacy v14");
    uStack_380 = 0;
    uStack_378 = _UNK_01a818b8;
    uStack_370 = 0;
    func_0x001eb5a8(auStack_368,"Legacy v15");
    uStack_350 = 0;
    uStack_348 = _UNK_01897730;
    uStack_340 = 0;
    func_0x001eb5a8(auStack_338,"Legacy v16");
    uStack_320 = 0;
    uStack_318 = _UNK_01a9c3a0;
    uStack_310 = 0;
    func_0x001eb5a8(auStack_308,"Legacy v17");
    uStack_2f0 = 0;
    uStack_2e8 = _UNK_01812f30;
    uStack_2e0 = 0;
    func_0x001eb5a8(auStack_2d8,"Legacy v18");
    uStack_2c0 = 0;
    uStack_2b8 = _UNK_01a818f0;
    uStack_2b0 = 0;
    func_0x001eb5a8(auStack_2a8,"Legacy v19");
    uStack_290 = 0;
    uStack_288 = _UNK_019f4d18;
    uStack_280 = 0;
    func_0x001eb5a8(auStack_278,"Legacy v20");
    uStack_260 = 0;
    uStack_258 = _UNK_01925b20;
    uStack_250 = 0;
    func_0x001eb5a8(auStack_248,"Legacy v21");
    uStack_230 = 0;
    uStack_228 = _UNK_01a9c3a8;
    uStack_220 = 0;
    func_0x001eb5a8(auStack_218,"Legacy v22");
    uStack_200 = 0;
    uStack_1f8 = _UNK_01897740;
    uStack_1f0 = 0;
    func_0x001eb5a8(auStack_1e8,"Legacy v23");
    uStack_1d0 = 0;
    uStack_1c8 = _UNK_01812f28;
    uStack_1c0 = 0;
    func_0x001eb5a8(auStack_1b8,"JPEG XR v1");
    uStack_1a0 = 0;
    uStack_198 = _UNK_01a9c3b0;
    uStack_190 = 0;
    func_0x001eb5a8(auStack_188,"JPEG XR v2");
    uStack_170 = 0;
    uStack_168 = _UNK_01897738;
    uStack_160 = 0;
    func_0x001eb5a8(auStack_158,"JPEG beta");
    uStack_140 = 0;
    uStack_138 = _UNK_01a9c3b8;
    uStack_130 = 0x1b;
    func_0x001eb5a8(auStack_128,"S-JPEG v1");
    func_0x01539098();
    ppuStack_110 = &__MergedGlobals;
    uStack_108 = _UNK_01a9c3c0;
    uStack_100 = 0x1c;
    func_0x001eb5a8(auStack_f8,"S-JPEG v2");
    func_0x01539098();
    ppuStack_e0 = &__MergedGlobals;
    uStack_d8 = _UNK_01a9c3c8;
    uStack_d0 = 0;
    func_0x001eb5a8(auStack_c8,"JPEG XL prototype");
    uStack_b0 = 0;
    uStack_a8 = _UNK_01a9c3d0;
    uStack_a0 = 1;
    func_0x001eb5a8(auStack_98,"JPEG XL v1");
    uStack_80 = 0;
    uStack_78 = _UNK_01a9c3d8;
    uStack_70 = 2;
    func_0x001eb5a8(auStack_68,"JPEG XL v2");
    func_0x015390d8();
    ppuStack_50 = &PTR_PTR_02011cb0;
    func_0x01539170(puVar2,&uStack_648,0x20);
    if (cStack_51 < '\0') goto LAB_0153880c;
    goto joined_r0x015386d4;
  }
  while( true ) {
    pbVar3 = pbVar4 + 0x10;
    puVar2 = *(undefined8 **)pbVar4;
    if (((*pbVar3 & 1) == 0) && (iVar1 = ___cxa_guard_acquire(0x205ec90), iVar1 != 0)) {
      func_0x01539118(*puVar2,puVar2[1]);
      __MergedGlobals_5 = 1;
      ___cxa_guard_release(0x205ec90);
    }
    if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_48) break;
    ___stack_chk_fail();
LAB_0153880c:
    __ZdlPv(auStack_68[0]);
joined_r0x015386d4:
    if (cStack_81 < '\0') {
      __ZdlPv(auStack_98[0]);
    }
    if (cStack_b1 < '\0') {
      __ZdlPv(auStack_c8[0]);
    }
    if (cStack_e1 < '\0') {
      __ZdlPv(auStack_f8[0]);
    }
    if (cStack_111 < '\0') {
      __ZdlPv(auStack_128[0]);
    }
    if (cStack_141 < '\0') {
      __ZdlPv(auStack_158[0]);
    }
    if (cStack_171 < '\0') {
      __ZdlPv(auStack_188[0]);
    }
    if (cStack_1a1 < '\0') {
      __ZdlPv(auStack_1b8[0]);
    }
    if (cStack_1d1 < '\0') {
      __ZdlPv(auStack_1e8[0]);
    }
    if (cStack_201 < '\0') {
      __ZdlPv(auStack_218[0]);
    }
    if (cStack_231 < '\0') {
      __ZdlPv(auStack_248[0]);
    }
    if (cStack_261 < '\0') {
      __ZdlPv(auStack_278[0]);
    }
    if (cStack_291 < '\0') {
      __ZdlPv(auStack_2a8[0]);
    }
    if (cStack_2c1 < '\0') {
      __ZdlPv(auStack_2d8[0]);
    }
    if (cStack_2f1 < '\0') {
      __ZdlPv(auStack_308[0]);
    }
    if (cStack_321 < '\0') {
      __ZdlPv(auStack_338[0]);
    }
    if (cStack_351 < '\0') {
      __ZdlPv(auStack_368[0]);
    }
    if (cStack_381 < '\0') {
      __ZdlPv(auStack_398[0]);
    }
    if (cStack_3b1 < '\0') {
      __ZdlPv(auStack_3c8[0]);
    }
    if (cStack_3e1 < '\0') {
      __ZdlPv(auStack_3f8[0]);
    }
    if (cStack_411 < '\0') {
      __ZdlPv(auStack_428[0]);
    }
    if (cStack_441 < '\0') {
      __ZdlPv(auStack_458[0]);
    }
    if (cStack_471 < '\0') {
      __ZdlPv(auStack_488[0]);
    }
    if (cStack_4a1 < '\0') {
      __ZdlPv(auStack_4b8[0]);
    }
    if (cStack_4d1 < '\0') {
      __ZdlPv(auStack_4e8[0]);
    }
    if (cStack_501 < '\0') {
      __ZdlPv(auStack_518[0]);
    }
    if (cStack_531 < '\0') {
      __ZdlPv(auStack_548[0]);
    }
    if (cStack_561 < '\0') {
      __ZdlPv(auStack_578[0]);
    }
    if (cStack_591 < '\0') {
      __ZdlPv(auStack_5a8[0]);
    }
    if (cStack_5c1 < '\0') {
      __ZdlPv(auStack_5d8[0]);
    }
    if (cStack_5f1 < '\0') {
      __ZdlPv(auStack_608[0]);
    }
    if (cStack_621 < '\0') {
      __ZdlPv(auStack_638[0]);
    }
    *(undefined8 **)pbVar3 = puVar2;
    ___cxa_guard_release((byte *)((long)pbVar3 + 8));
    pbVar4 = pbVar3;
  }
  return puVar2;
}


/* __ZZN5ProxyL14GetVersionListEvENK3$_0clEv @ 01539118 */

uint * __ZZN5ProxyL14GetVersionListEvENK3__0clEv(uint *param_1,long param_2,ulong param_3)

{
  undefined8 *puVar1;
  undefined8 *puVar2;
  ulong uVar3;
  code *pcVar4;
  uint *puVar5;
  long lVar6;
  ulong uVar7;
  long lVar8;
  undefined8 uVar9;
  long lVar10;
  long lVar11;
  undefined8 uVar12;
  undefined1 auVar13 [16];

  if (param_2 - (long)param_1 != 0) {
    uVar7 = 0;
    uVar3 = (param_2 - (long)param_1) / 0x30;
    puVar5 = param_1;
    if (uVar3 < 2) {
      uVar3 = 1;
    }
    do {
      param_1 = puVar5 + 0xc;
      if (uVar7 != *puVar5) {
        auVar13 = _abort();
        puVar5 = auVar13._0_8_;
        lVar8 = *(long *)PTR____stack_chk_guard_01d15188;
        puVar5[0] = 0;
        puVar5[1] = 0;
        puVar5[2] = 0;
        puVar5[3] = 0;
        puVar5[4] = 0;
        puVar5[5] = 0;
        if (param_3 == 0) goto LAB_01539260;
        if (param_3 < 0x555555555555556) {
          lVar10 = param_3 * 0x30;
          lVar6 = __Znwm(lVar10);
          lVar11 = 0;
          *(long *)puVar5 = lVar6;
          *(long *)(puVar5 + 2) = lVar6;
          *(long *)(puVar5 + 4) = lVar6 + lVar10;
          do {
            puVar1 = (undefined8 *)(auVar13._8_8_ + lVar11);
            puVar2 = (undefined8 *)(lVar6 + lVar11);
            uVar9 = *puVar1;
            *(undefined4 *)(puVar2 + 1) = *(undefined4 *)(puVar1 + 1);
            *puVar2 = uVar9;
            if (*(char *)((long)puVar1 + 0x27) < '\0') {
              func_0x00109e84(puVar2 + 2,puVar1[2],puVar1[3]);
            }
            else {
              uVar12 = puVar1[3];
              uVar9 = puVar1[2];
              puVar2[4] = puVar1[4];
              puVar2[3] = uVar12;
              puVar2[2] = uVar9;
            }
            *(undefined8 *)(lVar6 + lVar11 + 0x28) = puVar1[5];
            lVar11 = lVar11 + 0x30;
          } while (puVar1 + 6 != (undefined8 *)(auVar13._8_8_ + lVar10));
          *(long *)(puVar5 + 2) = lVar6 + lVar11;
LAB_01539260:
          if (*(long *)PTR____stack_chk_guard_01d15188 == lVar8) {
            return puVar5;
          }
          ___stack_chk_fail();
        }
        func_0x00108ee8();
                    /* WARNING: Does not return */
        pcVar4 = (code *)SoftwareBreakpoint(1,0x15392a0);
        (*pcVar4)();
      }
      uVar7 = uVar7 + 1;
      puVar5 = param_1;
    } while (uVar3 != uVar7);
  }
  return param_1;
}


/* __ZTSN5Proxy18ProxyContainer2006E @ 01a9c0d4 */

/* WARNING: Control flow encountered bad instruction data */

void __ZTSN5Proxy18ProxyContainer2006E(void)

{
                    /* WARNING: Bad instruction - Truncating control flow here */
  halt_baddata();
}


/* __ZTVN5Proxy7JPEG_XLE @ 01ffcce8 */

void __ZTVN5Proxy7JPEG_XLE(void)

{
  code *pcVar1;

                    /* WARNING: Does not return */
  pcVar1 = (code *)UndefinedInstructionException(0,0x1ffcce8);
  (*pcVar1)();
}


/* __ZTVN5Proxy18ProxyContainer2006E @ 01ffcef0 */

void __ZTVN5Proxy18ProxyContainer2006E(void)

{
  code *pcVar1;

                    /* WARNING: Does not return */
  pcVar1 = (code *)UndefinedInstructionException(0,0x1ffcef0);
  (*pcVar1)();
}
