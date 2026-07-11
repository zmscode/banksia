/* __ZN10CaptureOne10CameraCore12_GLOBAL__N_117CreatePOFilmCurveEPKhj @ 0031139c */

/* WARNING: Type propagation algorithm not settling */

undefined8
__ZN10CaptureOne10CameraCore12_GLOBAL__N_117CreatePOFilmCurveEPKhj(short *param_1,uint param_2)

{
  long lVar1;
  uint *puVar2;
  ulong uVar3;
  uint uVar4;
  uint uVar5;
  uint uVar6;
  short sVar7;
  uint uVar8;
  code *pcVar9;
  undefined8 uVar10;
  undefined8 *******pppppppuVar11;
  undefined4 *puVar12;
  undefined4 uVar13;
  ulong uVar14;
  uint *puVar15;
  uint uVar16;
  uint uVar17;
  uint uVar18;
  uint uVar19;
  long lStack_f8;
  long lStack_f0;
  long lStack_e0;
  long lStack_d8;
  undefined8 *******pppppppuStack_c8;
  ulong uStack_c0;
  undefined8 uStack_b8;
  undefined8 *******pppppppuStack_b0;
  ulong uStack_a8;
  undefined8 uStack_a0;
  long alStack_98 [3];
  uint *puStack_80;
  long lStack_78;

  lStack_78 = *(long *)PTR____stack_chk_guard_01d15188;
  if (param_2 < 10) {
    puVar12 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar12 = 0xffffd508;
    ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
LAB_003118fc:
    puVar12 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar12 = 0xffffd505;
    ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
LAB_0031191c:
    puVar12 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar12 = 0xffffd506;
    ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
LAB_0031193c:
    puVar12 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar12 = 0xffffd505;
    ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
    goto LAB_00311a8c;
  }
  sVar7 = *param_1;
  if (sVar7 == 0x4949 || sVar7 == 0x4d4d) {
    if ((ulong)param_2 - 2 < 4) goto LAB_003118fc;
    uVar6 = *(uint *)(param_1 + 1);
    puStack_80 = (uint *)(param_1 + 3);
    uVar8 = (uVar6 & 0xff00ff00) >> 8 | (uVar6 & 0xff00ff) << 8;
    uVar8 = uVar8 >> 0x10 | uVar8 << 0x10;
    if (sVar7 != 0x4d4d) {
      uVar8 = uVar6;
    }
    if (uVar8 < 2) goto LAB_0031191c;
    lVar1 = (long)param_1 + (ulong)param_2;
    func_0x0031690c(alStack_98,&puStack_80,lVar1,sVar7 == 0x4d4d);
    if ((ulong)(lVar1 - (long)puStack_80) < 4) goto LAB_0031193c;
    uVar4 = *puStack_80;
    uVar6 = (uVar4 & 0xff00ff00) >> 8 | (uVar4 & 0xff00ff) << 8;
    uVar6 = uVar6 >> 0x10 | uVar6 << 0x10;
    if (sVar7 != 0x4d4d) {
      uVar6 = uVar4;
    }
    if (3 < (lVar1 - (long)puStack_80) - 4U) {
      uVar18 = puStack_80[1];
      puVar2 = puStack_80 + 2;
      uVar4 = (uVar18 & 0xff00ff00) >> 8 | (uVar18 & 0xff00ff) << 8;
      uVar4 = uVar4 >> 0x10 | uVar4 << 0x10;
      if (sVar7 != 0x4d4d) {
        uVar4 = uVar18;
      }
      uVar14 = (ulong)uVar4;
      puStack_80 = puVar2;
      if ((long)uVar14 <= lVar1 - (long)puVar2) {
        if (uVar4 < 0x17) {
          uStack_a0 = CONCAT17((char)uVar4,(undefined7)uStack_a0);
          pppppppuVar11 = &pppppppuStack_b0;
          if (uVar4 != 0) goto LAB_003114e0;
        }
        else {
          uVar3 = (uVar14 & 0xfffffff8) + 8;
          if ((uVar14 | 7) != 0x17) {
            uVar3 = uVar14 | 7;
          }
          pppppppuVar11 = (undefined8 *******)__Znwm(uVar3 + 1);
          uStack_a0 = uVar3 + 1 | 0x8000000000000000;
          pppppppuStack_b0 = pppppppuVar11;
          uStack_a8 = uVar14;
LAB_003114e0:
          _memmove(pppppppuVar11,puVar2,uVar14);
        }
        *(undefined1 *)((long)pppppppuVar11 + uVar14) = 0;
        puVar2 = (uint *)((long)puStack_80 + uVar14);
        if (3 < (ulong)(lVar1 - (long)puVar2)) {
          puVar15 = puVar2 + 1;
          uVar18 = *puVar2;
          uVar4 = (uVar18 & 0xff00ff00) >> 8 | (uVar18 & 0xff00ff) << 8;
          uVar4 = uVar4 >> 0x10 | uVar4 << 0x10;
          if (sVar7 != 0x4d4d) {
            uVar4 = uVar18;
          }
          uVar14 = (ulong)uVar4;
          puStack_80 = puVar15;
          if ((long)uVar14 <= lVar1 - (long)puVar15) {
            if (0x16 < uVar4) {
              uVar3 = (uVar14 & 0xfffffff8) + 8;
              if ((uVar14 | 7) != 0x17) {
                uVar3 = uVar14 | 7;
              }
              pppppppuVar11 = (undefined8 *******)__Znwm(uVar3 + 1);
              uStack_b8 = uVar3 + 1 | 0x8000000000000000;
              pppppppuStack_c8 = pppppppuVar11;
              uStack_c0 = uVar14;
LAB_00311650:
              _memmove(pppppppuVar11,puVar15,uVar14);
              *(undefined1 *)((long)pppppppuVar11 + uVar14) = 0;
              if (uVar8 != 2) goto LAB_0031154c;
LAB_0031166c:
              uVar10 = func_0x01556328(0x78);
              func_0x01553c84(uVar10,&pppppppuStack_c8,&pppppppuStack_b0,alStack_98,uVar6,
                              &UNK_0003020c,0x42);
              goto LAB_00311698;
            }
            uStack_b8 = CONCAT17((char)uVar4,(undefined7)uStack_b8);
            pppppppuVar11 = &pppppppuStack_c8;
            if (uVar4 != 0) goto LAB_00311650;
                    /* WARNING: Ignoring partial resolution of indirect */
            pppppppuStack_c8._0_1_ = 0;
            if (uVar8 == 2) goto LAB_0031166c;
LAB_0031154c:
            if (uVar8 != 3) {
              puVar2 = (uint *)((long)puStack_80 + uVar14);
              uVar14 = lVar1 - (long)puVar2;
              if (uVar14 < 4) {
                puVar12 = (undefined4 *)___cxa_allocate_exception(4);
                *puVar12 = 0xffffd505;
                ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
                goto LAB_00311a8c;
              }
              puStack_80 = puVar2 + 1;
              uVar18 = *puVar2;
              uVar4 = (uVar18 & 0xff00ff00) >> 8 | (uVar18 & 0xff00ff) << 8;
              uVar4 = uVar4 >> 0x10 | uVar4 << 0x10;
              if (sVar7 != 0x4d4d) {
                uVar4 = uVar18;
              }
              if ((ulong)(lVar1 - (long)puStack_80) < 4) {
                puVar12 = (undefined4 *)___cxa_allocate_exception(4);
                *puVar12 = 0xffffd505;
                ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
                goto LAB_00311a8c;
              }
              uVar16 = puVar2[1];
              uVar18 = (uVar16 & 0xff00ff00) >> 8 | (uVar16 & 0xff00ff) << 8;
              uVar18 = uVar18 >> 0x10 | uVar18 << 0x10;
              if (sVar7 != 0x4d4d) {
                uVar18 = uVar16;
              }
              if (uVar14 - 8 < 4) {
                puVar12 = (undefined4 *)___cxa_allocate_exception(4);
                *puVar12 = 0xffffd505;
                ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
                goto LAB_00311a8c;
              }
              uVar19 = puVar2[2];
              uVar16 = (uVar19 & 0xff00ff00) >> 8 | (uVar19 & 0xff00ff) << 8;
              uVar16 = uVar16 >> 0x10 | uVar16 << 0x10;
              if (sVar7 != 0x4d4d) {
                uVar16 = uVar19;
              }
              if (uVar14 - 0xc < 4) {
                puVar12 = (undefined4 *)___cxa_allocate_exception(4);
                *puVar12 = 0xffffd505;
                ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
                goto LAB_00311a8c;
              }
              uVar5 = puVar2[3];
              uVar19 = (uVar5 & 0xff00ff00) >> 8 | (uVar5 & 0xff00ff) << 8;
              uVar19 = uVar19 >> 0x10 | uVar19 << 0x10;
              if (sVar7 != 0x4d4d) {
                uVar19 = uVar5;
              }
              if (uVar8 == 4) {
                uVar10 = func_0x01556328(0x78);
                func_0x01553d14(uVar18,uVar10,&pppppppuStack_c8,&pppppppuStack_b0,alStack_98,uVar6,
                                uVar16,uVar19,uVar4);
              }
              else {
                if ((ulong)(lVar1 - (long)(puVar2 + 4)) < 4) {
                  puVar12 = (undefined4 *)___cxa_allocate_exception(4);
                  *puVar12 = 0xffffd505;
                  ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
                  goto LAB_00311a8c;
                }
                uVar17 = puVar2[4];
                puStack_80 = puVar2 + 5;
                uVar5 = (uVar17 & 0xff00ff00) >> 8 | (uVar17 & 0xff00ff) << 8;
                uVar5 = uVar5 >> 0x10 | uVar5 << 0x10;
                if (sVar7 != 0x4d4d) {
                  uVar5 = uVar17;
                }
                if (uVar8 == 5) {
                  uVar10 = func_0x01556328(0x78);
                  func_0x01553da0(uVar18,uVar10,uVar5,&pppppppuStack_c8,&pppppppuStack_b0,alStack_98
                                  ,uVar6,uVar16,uVar19,uVar4);
                }
                else {
                  func_0x0031690c(&lStack_e0,&puStack_80,lVar1,sVar7 == 0x4d4d);
                  func_0x0031690c(&lStack_f8,&puStack_80,lVar1,sVar7 == 0x4d4d);
                  if (uVar8 != 6) {
                    if ((ulong)(lVar1 - (long)puStack_80) < 4) {
                      puVar12 = (undefined4 *)___cxa_allocate_exception(4);
                      uVar13 = 0xffffd505;
                    }
                    else {
                      uVar17 = *puStack_80;
                      uVar19 = (uVar17 & 0xff00ff00) >> 8 | (uVar17 & 0xff00ff) << 8;
                      uVar19 = uVar19 >> 0x10 | uVar19 << 0x10;
                      if (sVar7 != 0x4d4d) {
                        uVar19 = uVar17;
                      }
                      if (uVar8 == 7) {
                        uVar10 = func_0x01556328(0x78);
                        func_0x01553e84(uVar18,uVar19,uVar10,uVar5,&pppppppuStack_c8,
                                        &pppppppuStack_b0,alStack_98,&lStack_e0,&lStack_f8,uVar6,
                                        uVar16,uVar4);
                        goto LAB_00311870;
                      }
                      puVar12 = (undefined4 *)___cxa_allocate_exception(4);
                      uVar13 = 0xffffd506;
                    }
                    *puVar12 = uVar13;
                    ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
                    goto LAB_00311a8c;
                  }
                  uVar10 = func_0x01556328(0x78);
                  func_0x01553e30(uVar18,uVar10,uVar5,&pppppppuStack_c8,&pppppppuStack_b0,alStack_98
                                  ,&lStack_e0,&lStack_f8,uVar6,uVar16,uVar4);
LAB_00311870:
                  if (lStack_f8 != 0) {
                    lStack_f0 = lStack_f8;
                    __ZdlPv();
                  }
                  if (lStack_e0 != 0) {
                    lStack_d8 = lStack_e0;
                    __ZdlPv();
                  }
                }
              }
LAB_00311698:
              if ((long)uStack_b8 < 0) {
                __ZdlPv(pppppppuStack_c8);
              }
              if ((long)uStack_a0 < 0) {
                __ZdlPv(pppppppuStack_b0);
              }
              if (alStack_98[0] != 0) {
                __ZdlPv();
              }
              if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_78) {
                return uVar10;
              }
              ___stack_chk_fail();
              goto LAB_00311964;
            }
            goto LAB_00311984;
          }
        }
        puVar12 = (undefined4 *)___cxa_allocate_exception(4);
        *puVar12 = 0xffffd505;
        ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
        goto LAB_00311a8c;
      }
    }
    puVar12 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar12 = 0xffffd505;
    ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
  }
  else {
LAB_00311964:
    puVar12 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar12 = 0xffffd507;
    ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
LAB_00311984:
    puVar12 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar12 = 0xffffd506;
    ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
  }
LAB_00311a8c:
                    /* WARNING: Does not return */
  pcVar9 = (code *)SoftwareBreakpoint(1,0x311a90);
  (*pcVar9)();
}


/* __ZN10CaptureOne10CameraCore17CreatePOFilmCurveER6POData @ 00311bbc */

/* WARNING: Type propagation algorithm not settling */

undefined8 __ZN10CaptureOne10CameraCore17CreatePOFilmCurveER6POData(undefined8 param_1)

{
  long lVar1;
  uint *puVar2;
  ulong uVar3;
  uint uVar4;
  uint uVar5;
  short sVar6;
  uint uVar7;
  code *pcVar8;
  uint uVar9;
  undefined8 uVar10;
  undefined8 *******pppppppuVar11;
  undefined4 *puVar12;
  short *psVar13;
  undefined4 uVar14;
  ulong uVar15;
  uint *puVar16;
  uint uVar17;
  uint uVar18;
  uint uVar19;
  uint uVar20;
  long lStack_f8;
  long lStack_f0;
  long lStack_e0;
  long lStack_d8;
  undefined8 *******pppppppuStack_c8;
  ulong uStack_c0;
  undefined8 uStack_b8;
  undefined8 *******pppppppuStack_b0;
  ulong uStack_a8;
  undefined8 uStack_a0;
  long alStack_98 [3];
  uint *puStack_80;
  long lStack_78;

  psVar13 = (short *)func_0x00c58108();
  uVar9 = func_0x0000af70(param_1);
  lStack_78 = *(long *)PTR____stack_chk_guard_01d15188;
  if (uVar9 < 10) {
    puVar12 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar12 = 0xffffd508;
    ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
LAB_003118fc:
    puVar12 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar12 = 0xffffd505;
    ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
LAB_0031191c:
    puVar12 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar12 = 0xffffd506;
    ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
LAB_0031193c:
    puVar12 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar12 = 0xffffd505;
    ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
    goto LAB_00311a8c;
  }
  sVar6 = *psVar13;
  if (sVar6 == 0x4949 || sVar6 == 0x4d4d) {
    if ((ulong)uVar9 - 2 < 4) goto LAB_003118fc;
    uVar5 = *(uint *)(psVar13 + 1);
    puStack_80 = (uint *)(psVar13 + 3);
    uVar7 = (uVar5 & 0xff00ff00) >> 8 | (uVar5 & 0xff00ff) << 8;
    uVar7 = uVar7 >> 0x10 | uVar7 << 0x10;
    if (sVar6 != 0x4d4d) {
      uVar7 = uVar5;
    }
    if (uVar7 < 2) goto LAB_0031191c;
    lVar1 = (long)psVar13 + (ulong)uVar9;
    func_0x0031690c(alStack_98,&puStack_80,lVar1,sVar6 == 0x4d4d);
    if ((ulong)(lVar1 - (long)puStack_80) < 4) goto LAB_0031193c;
    uVar5 = *puStack_80;
    uVar9 = (uVar5 & 0xff00ff00) >> 8 | (uVar5 & 0xff00ff) << 8;
    uVar9 = uVar9 >> 0x10 | uVar9 << 0x10;
    if (sVar6 != 0x4d4d) {
      uVar9 = uVar5;
    }
    if (3 < (lVar1 - (long)puStack_80) - 4U) {
      uVar19 = puStack_80[1];
      puVar2 = puStack_80 + 2;
      uVar5 = (uVar19 & 0xff00ff00) >> 8 | (uVar19 & 0xff00ff) << 8;
      uVar5 = uVar5 >> 0x10 | uVar5 << 0x10;
      if (sVar6 != 0x4d4d) {
        uVar5 = uVar19;
      }
      uVar15 = (ulong)uVar5;
      puStack_80 = puVar2;
      if ((long)uVar15 <= lVar1 - (long)puVar2) {
        if (uVar5 < 0x17) {
          uStack_a0 = CONCAT17((char)uVar5,(undefined7)uStack_a0);
          pppppppuVar11 = &pppppppuStack_b0;
          if (uVar5 != 0) goto LAB_003114e0;
        }
        else {
          uVar3 = (uVar15 & 0xfffffff8) + 8;
          if ((uVar15 | 7) != 0x17) {
            uVar3 = uVar15 | 7;
          }
          pppppppuVar11 = (undefined8 *******)__Znwm(uVar3 + 1);
          uStack_a0 = uVar3 + 1 | 0x8000000000000000;
          pppppppuStack_b0 = pppppppuVar11;
          uStack_a8 = uVar15;
LAB_003114e0:
          _memmove(pppppppuVar11,puVar2,uVar15);
        }
        *(undefined1 *)((long)pppppppuVar11 + uVar15) = 0;
        puVar2 = (uint *)((long)puStack_80 + uVar15);
        if (3 < (ulong)(lVar1 - (long)puVar2)) {
          puVar16 = puVar2 + 1;
          uVar19 = *puVar2;
          uVar5 = (uVar19 & 0xff00ff00) >> 8 | (uVar19 & 0xff00ff) << 8;
          uVar5 = uVar5 >> 0x10 | uVar5 << 0x10;
          if (sVar6 != 0x4d4d) {
            uVar5 = uVar19;
          }
          uVar15 = (ulong)uVar5;
          puStack_80 = puVar16;
          if ((long)uVar15 <= lVar1 - (long)puVar16) {
            if (0x16 < uVar5) {
              uVar3 = (uVar15 & 0xfffffff8) + 8;
              if ((uVar15 | 7) != 0x17) {
                uVar3 = uVar15 | 7;
              }
              pppppppuVar11 = (undefined8 *******)__Znwm(uVar3 + 1);
              uStack_b8 = uVar3 + 1 | 0x8000000000000000;
              pppppppuStack_c8 = pppppppuVar11;
              uStack_c0 = uVar15;
LAB_00311650:
              _memmove(pppppppuVar11,puVar16,uVar15);
              *(undefined1 *)((long)pppppppuVar11 + uVar15) = 0;
              if (uVar7 != 2) goto LAB_0031154c;
LAB_0031166c:
              uVar10 = func_0x01556328(0x78);
              func_0x01553c84(uVar10,&pppppppuStack_c8,&pppppppuStack_b0,alStack_98,uVar9,
                              &UNK_0003020c,0x42);
              goto LAB_00311698;
            }
            uStack_b8 = CONCAT17((char)uVar5,(undefined7)uStack_b8);
            pppppppuVar11 = &pppppppuStack_c8;
            if (uVar5 != 0) goto LAB_00311650;
                    /* WARNING: Ignoring partial resolution of indirect */
            pppppppuStack_c8._0_1_ = 0;
            if (uVar7 == 2) goto LAB_0031166c;
LAB_0031154c:
            if (uVar7 != 3) {
              puVar2 = (uint *)((long)puStack_80 + uVar15);
              uVar15 = lVar1 - (long)puVar2;
              if (uVar15 < 4) {
                puVar12 = (undefined4 *)___cxa_allocate_exception(4);
                *puVar12 = 0xffffd505;
                ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
                goto LAB_00311a8c;
              }
              puStack_80 = puVar2 + 1;
              uVar19 = *puVar2;
              uVar5 = (uVar19 & 0xff00ff00) >> 8 | (uVar19 & 0xff00ff) << 8;
              uVar5 = uVar5 >> 0x10 | uVar5 << 0x10;
              if (sVar6 != 0x4d4d) {
                uVar5 = uVar19;
              }
              if ((ulong)(lVar1 - (long)puStack_80) < 4) {
                puVar12 = (undefined4 *)___cxa_allocate_exception(4);
                *puVar12 = 0xffffd505;
                ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
                goto LAB_00311a8c;
              }
              uVar17 = puVar2[1];
              uVar19 = (uVar17 & 0xff00ff00) >> 8 | (uVar17 & 0xff00ff) << 8;
              uVar19 = uVar19 >> 0x10 | uVar19 << 0x10;
              if (sVar6 != 0x4d4d) {
                uVar19 = uVar17;
              }
              if (uVar15 - 8 < 4) {
                puVar12 = (undefined4 *)___cxa_allocate_exception(4);
                *puVar12 = 0xffffd505;
                ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
                goto LAB_00311a8c;
              }
              uVar20 = puVar2[2];
              uVar17 = (uVar20 & 0xff00ff00) >> 8 | (uVar20 & 0xff00ff) << 8;
              uVar17 = uVar17 >> 0x10 | uVar17 << 0x10;
              if (sVar6 != 0x4d4d) {
                uVar17 = uVar20;
              }
              if (uVar15 - 0xc < 4) {
                puVar12 = (undefined4 *)___cxa_allocate_exception(4);
                *puVar12 = 0xffffd505;
                ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
                goto LAB_00311a8c;
              }
              uVar4 = puVar2[3];
              uVar20 = (uVar4 & 0xff00ff00) >> 8 | (uVar4 & 0xff00ff) << 8;
              uVar20 = uVar20 >> 0x10 | uVar20 << 0x10;
              if (sVar6 != 0x4d4d) {
                uVar20 = uVar4;
              }
              if (uVar7 == 4) {
                uVar10 = func_0x01556328(0x78);
                func_0x01553d14(uVar19,uVar10,&pppppppuStack_c8,&pppppppuStack_b0,alStack_98,uVar9,
                                uVar17,uVar20,uVar5);
              }
              else {
                if ((ulong)(lVar1 - (long)(puVar2 + 4)) < 4) {
                  puVar12 = (undefined4 *)___cxa_allocate_exception(4);
                  *puVar12 = 0xffffd505;
                  ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
                  goto LAB_00311a8c;
                }
                uVar18 = puVar2[4];
                puStack_80 = puVar2 + 5;
                uVar4 = (uVar18 & 0xff00ff00) >> 8 | (uVar18 & 0xff00ff) << 8;
                uVar4 = uVar4 >> 0x10 | uVar4 << 0x10;
                if (sVar6 != 0x4d4d) {
                  uVar4 = uVar18;
                }
                if (uVar7 == 5) {
                  uVar10 = func_0x01556328(0x78);
                  func_0x01553da0(uVar19,uVar10,uVar4,&pppppppuStack_c8,&pppppppuStack_b0,alStack_98
                                  ,uVar9,uVar17,uVar20,uVar5);
                }
                else {
                  func_0x0031690c(&lStack_e0,&puStack_80,lVar1,sVar6 == 0x4d4d);
                  func_0x0031690c(&lStack_f8,&puStack_80,lVar1,sVar6 == 0x4d4d);
                  if (uVar7 != 6) {
                    if ((ulong)(lVar1 - (long)puStack_80) < 4) {
                      puVar12 = (undefined4 *)___cxa_allocate_exception(4);
                      uVar14 = 0xffffd505;
                    }
                    else {
                      uVar18 = *puStack_80;
                      uVar20 = (uVar18 & 0xff00ff00) >> 8 | (uVar18 & 0xff00ff) << 8;
                      uVar20 = uVar20 >> 0x10 | uVar20 << 0x10;
                      if (sVar6 != 0x4d4d) {
                        uVar20 = uVar18;
                      }
                      if (uVar7 == 7) {
                        uVar10 = func_0x01556328(0x78);
                        func_0x01553e84(uVar19,uVar20,uVar10,uVar4,&pppppppuStack_c8,
                                        &pppppppuStack_b0,alStack_98,&lStack_e0,&lStack_f8,uVar9,
                                        uVar17,uVar5);
                        goto LAB_00311870;
                      }
                      puVar12 = (undefined4 *)___cxa_allocate_exception(4);
                      uVar14 = 0xffffd506;
                    }
                    *puVar12 = uVar14;
                    ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
                    goto LAB_00311a8c;
                  }
                  uVar10 = func_0x01556328(0x78);
                  func_0x01553e30(uVar19,uVar10,uVar4,&pppppppuStack_c8,&pppppppuStack_b0,alStack_98
                                  ,&lStack_e0,&lStack_f8,uVar9,uVar17,uVar5);
LAB_00311870:
                  if (lStack_f8 != 0) {
                    lStack_f0 = lStack_f8;
                    __ZdlPv();
                  }
                  if (lStack_e0 != 0) {
                    lStack_d8 = lStack_e0;
                    __ZdlPv();
                  }
                }
              }
LAB_00311698:
              if ((long)uStack_b8 < 0) {
                __ZdlPv(pppppppuStack_c8);
              }
              if ((long)uStack_a0 < 0) {
                __ZdlPv(pppppppuStack_b0);
              }
              if (alStack_98[0] != 0) {
                __ZdlPv();
              }
              if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_78) {
                return uVar10;
              }
              ___stack_chk_fail();
              goto LAB_00311964;
            }
            goto LAB_00311984;
          }
        }
        puVar12 = (undefined4 *)___cxa_allocate_exception(4);
        *puVar12 = 0xffffd505;
        ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
        goto LAB_00311a8c;
      }
    }
    puVar12 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar12 = 0xffffd505;
    ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
  }
  else {
LAB_00311964:
    puVar12 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar12 = 0xffffd507;
    ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
LAB_00311984:
    puVar12 = (undefined4 *)___cxa_allocate_exception(4);
    *puVar12 = 0xffffd506;
    ___cxa_throw(puVar12,&__ZTI15FilmCurveErrors,0);
  }
LAB_00311a8c:
                    /* WARNING: Does not return */
  pcVar8 = (code *)SoftwareBreakpoint(1,0x311a90);
  (*pcVar8)();
}


/* __ZN10CaptureOne10CameraCore17CreatePOFilmCurveEONSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEERKNS1_6vectorINS1_5tupleIJddEEENS5_ISB_EEEE @ 00311bf0 */

ulong __ZN10CaptureOne10CameraCore17CreatePOFilmCurveEONSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEERKNS1_6vectorINS1_5tupleIJddEEENS5_ISB_EEEE
                (undefined8 param_1,int param_2)

{
  long lVar1;
  undefined2 uVar2;
  undefined4 uVar3;
  uint uVar4;
  ulong uVar5;
  undefined8 uVar6;
  long extraout_x1;
  long extraout_x1_00;
  undefined8 *puVar7;
  undefined4 uVar8;
  ulong uVar9;
  int iVar10;
  ulong uVar11;
  uint uVar12;
  long *plVar13;
  int *piVar14;
  long lVar15;
  ulong uVar16;
  long lVar17;
  undefined1 uStack_b9;
  long lStack_b8;
  undefined8 uStack_50;
  undefined8 uStack_48;
  long lStack_40;
  long lStack_38;

  puVar7 = &uStack_50;
  lStack_38 = *(long *)PTR____stack_chk_guard_01d15188;
  uStack_50 = 0;
  uStack_48 = 0;
  lStack_40 = 0;
  uVar5 = func_0x01556328(0x78);
  uVar8 = 0;
  func_0x01553c84(uVar5,param_1);
  if (lStack_40 < 0) {
    __ZdlPv(uStack_50);
  }
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_38) {
    return uVar5;
  }
  uVar6 = ___stack_chk_fail();
  func_0x015561e4(uVar5);
  if (lStack_40 < 0) {
    __ZdlPv(uStack_50);
  }
  __Unwind_Resume(uVar6);
  lStack_b8 = *(long *)PTR____stack_chk_guard_01d15188;
  lVar17 = *(long *)(extraout_x1 + 0x38);
  lVar15 = *(long *)(extraout_x1 + 0x40);
  lVar1 = 0;
  if (lVar15 != lVar17) {
    lVar1 = LZCOUNT(lVar15 - lVar17 >> 3) * -2 + 0x7e;
  }
  uVar5 = func_0x00315548(lVar17,lVar15,&uStack_b9,lVar1,1);
  uVar9 = *(long *)(extraout_x1 + 0x40) - *(long *)(extraout_x1 + 0x38);
  if ((uVar9 & 0x7fff8) != 0) {
    uVar11 = (long)uVar9 >> 3;
    *(short *)puVar7 = (short)uVar11;
    if ((uVar11 & 0xffff) != 0) {
      uVar16 = 0;
      uVar12 = ((uint)uVar11 & 0xffff) * 0xc + 6;
      lVar17 = ((uVar9 >> 3 & 0xffff) + (uVar9 >> 3 & 0xffff) * 2) * 4;
      lVar1 = 0;
      do {
        while( true ) {
          lVar15 = lVar1;
          if (uVar16 < (ulong)(*(long *)(extraout_x1 + 0x40) - *(long *)(extraout_x1 + 0x38) >> 3))
          {
            plVar13 = *(long **)(*(long *)(extraout_x1 + 0x38) + uVar16 * 8);
          }
          else {
            plVar13 = (long *)0x0;
          }
          uVar2 = (**(code **)(*plVar13 + 0x58))(plVar13);
          *(undefined2 *)((long)puVar7 + lVar15 + 2) = uVar2;
          uVar2 = (**(code **)(*plVar13 + 0x60))(plVar13);
          *(undefined2 *)((long)puVar7 + lVar15 + 4) = uVar2;
          uVar3 = (**(code **)(*plVar13 + 0x38))(plVar13);
          *(undefined4 *)((long)puVar7 + lVar15 + 6) = uVar3;
          uVar4 = (**(code **)(*plVar13 + 0x50))(plVar13);
          piVar14 = (int *)((long)puVar7 + lVar15 + 10);
          *piVar14 = 0;
          if (uVar4 < 5) break;
          uVar12 = (uVar12 & 1) + uVar12;
          *piVar14 = uVar12 + param_2;
          uVar6 = (**(code **)(*plVar13 + 0x48))(plVar13);
          uVar5 = _memcpy((long)puVar7 + (ulong)uVar12,uVar6,uVar4);
          uVar12 = uVar12 + uVar4;
          uVar16 = uVar16 + 1;
          lVar1 = lVar15 + 0xc;
          if (lVar17 - (lVar15 + 0xc) == 0) goto LAB_00311e64;
        }
        uVar6 = (**(code **)(*plVar13 + 0x48))(plVar13);
        uVar5 = _memcpy(piVar14,uVar6,uVar4);
        uVar16 = uVar16 + 1;
        lVar1 = lVar15 + 0xc;
      } while (lVar17 - (lVar15 + 0xc) != 0);
LAB_00311e64:
      puVar7 = (undefined8 *)((long)puVar7 + lVar15 + 0xc);
    }
    *(undefined4 *)((long)puVar7 + 2) = uVar8;
  }
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_b8) {
    return uVar5;
  }
  ___stack_chk_fail();
  uVar5 = *(long *)(extraout_x1_00 + 0x40) - *(long *)(extraout_x1_00 + 0x38);
  iVar10 = (int)(uVar5 >> 3);
  if (iVar10 != 0) {
    uVar9 = 0;
    uVar12 = iVar10 * 0xc | 2;
    do {
      uVar4 = (**(code **)(**(long **)(*(long *)(extraout_x1_00 + 0x38) + uVar9 * 8) + 0x50))();
      iVar10 = 0;
      if (4 < uVar4) {
        iVar10 = uVar4 + 1;
      }
      uVar12 = iVar10 + uVar12;
      uVar9 = uVar9 + 1;
    } while ((uVar5 >> 3 & 0xffffffff) != uVar9);
    return (ulong)(uVar12 + (uVar12 & 1) + 4);
  }
  return 0;
}


/* _POFilmCurveGetCurve @ 00313754 */

undefined8 _POFilmCurveGetCurve(long param_1)

{
  if (param_1 != 0) {
    return *(undefined8 *)(param_1 + 0x48);
  }
  return 0;
}


/* _POFilmCurveGetCCDCurve @ 00313760 */

undefined8 _POFilmCurveGetCCDCurve(long param_1)

{
  if (param_1 != 0) {
    return *(undefined8 *)(param_1 + 0x50);
  }
  return 0;
}


/* _POFilmCurveGetContrastCurve @ 0031376c */

undefined8 _POFilmCurveGetContrastCurve(long param_1)

{
  if (param_1 != 0) {
    return *(undefined8 *)(param_1 + 0x58);
  }
  return 0;
}


/* __ZN10CaptureOne10CameraCore12_GLOBAL__N_124DeserialiseFilmCurveDataINSt3__16vectorINS3_5tupleIJddEEENS3_9allocatorIS6_EEEEEET_RPKhSC_b @ 0031690c */

double * __ZN10CaptureOne10CameraCore12_GLOBAL__N_124DeserialiseFilmCurveDataINSt3__16vectorINS3_5tupleIJddEEENS3_9allocatorIS6_EEEEEET_RPKhSC_b
                   (double *param_1,long *param_2,long param_3,int param_4)

{
  ulong uVar1;
  uint uVar2;
  uint uVar3;
  uint uVar4;
  code *pcVar5;
  double *pdVar6;
  undefined4 *puVar7;
  undefined8 uVar8;
  uint *puVar9;
  ulong uVar10;
  double *pdVar11;
  double *pdVar12;
  ulong uVar13;
  long *unaff_x19;
  double *pdVar14;
  uint uVar15;
  double *pdVar16;
  long lVar17;
  double *pdVar18;
  double dVar19;
  double dVar20;

  puVar9 = (uint *)*param_2;
  if (3 < (ulong)(param_3 - (long)puVar9)) {
    uVar15 = *puVar9;
    *param_2 = (long)(puVar9 + 1);
    uVar3 = (uVar15 & 0xff00ff00) >> 8 | (uVar15 & 0xff00ff) << 8;
    uVar3 = uVar3 >> 0x10 | uVar3 << 0x10;
    if (param_4 == 0) {
      uVar3 = uVar15;
    }
    if ((ulong)(uVar3 << 1) << 2 <= (ulong)(param_3 - (long)(puVar9 + 1))) {
      *param_1 = 0.0;
      param_1[1] = 0.0;
      param_1[2] = 0.0;
      if (uVar3 == 0) {
        return param_1;
      }
      pdVar6 = (double *)__Znwm((ulong)uVar3 << 4);
      uVar15 = 0;
      *param_1 = (double)pdVar6;
      param_1[1] = (double)pdVar6;
      param_1[2] = (double)(pdVar6 + (ulong)uVar3 * 2);
      pdVar14 = pdVar6;
LAB_003169c0:
      do {
        puVar9 = (uint *)*param_2;
        if ((ulong)(param_3 - (long)puVar9) < 4) {
          puVar7 = (undefined4 *)___cxa_allocate_exception(4);
          *puVar7 = 0xffffd505;
          ___cxa_throw(puVar7,&__ZTI15FilmCurveErrors,0);
LAB_00316b84:
                    /* WARNING: Does not return */
          pcVar5 = (code *)SoftwareBreakpoint(1,0x316b88);
          (*pcVar5)();
        }
        uVar2 = *puVar9;
        *param_2 = (long)(puVar9 + 1);
        uVar4 = (uVar2 & 0xff00ff00) >> 8 | (uVar2 & 0xff00ff) << 8;
        uVar4 = uVar4 >> 0x10 | uVar4 << 0x10;
        if (param_4 == 0) {
          uVar4 = uVar2;
        }
        if ((ulong)(param_3 - (long)(puVar9 + 1)) < 4) {
          puVar7 = (undefined4 *)___cxa_allocate_exception(4);
          *puVar7 = 0xffffd505;
          ___cxa_throw(puVar7,&__ZTI15FilmCurveErrors,0);
          goto LAB_00316b84;
        }
        dVar19 = (double)uVar4 * 2.3283064370807974e-10;
        uVar2 = puVar9[1];
        *param_2 = (long)(puVar9 + 2);
        uVar4 = (uVar2 & 0xff00ff00) >> 8 | (uVar2 & 0xff00ff) << 8;
        uVar4 = uVar4 >> 0x10 | uVar4 << 0x10;
        if (param_4 == 0) {
          uVar4 = uVar2;
        }
        dVar20 = (double)uVar4 * 2.3283064370807974e-10;
        if (pdVar14 < (double *)param_1[2]) {
          *pdVar14 = dVar19;
          pdVar14[1] = dVar20;
          pdVar14 = pdVar14 + 2;
          param_1[1] = (double)pdVar14;
          uVar15 = uVar15 + 1;
          if (uVar15 == uVar3) {
            return pdVar6;
          }
          goto LAB_003169c0;
        }
        pdVar16 = (double *)*param_1;
        lVar17 = (long)pdVar14 - (long)pdVar16 >> 4;
        uVar1 = lVar17 + 1;
        if (uVar1 >> 0x3c != 0) {
          func_0x00108ee8(param_1);
          goto LAB_00316b84;
        }
        uVar10 = (long)param_1[2] - (long)pdVar16;
        uVar13 = (long)uVar10 >> 3;
        if (uVar13 <= uVar1) {
          uVar13 = uVar1;
        }
        if (0x7fffffffffffffef < uVar10) {
          uVar13 = 0xfffffffffffffff;
        }
        if (uVar13 == 0) {
          pdVar6 = (double *)0x0;
          pdVar12 = (double *)(lVar17 * 0x10);
          pdVar11 = (double *)0x0;
          *pdVar12 = dVar19;
          pdVar12[1] = dVar20;
          pdVar18 = pdVar12 + 2;
          if (pdVar14 == pdVar16) goto LAB_00316ae0;
LAB_00316ab0:
          do {
            dVar19 = pdVar14[-2];
            pdVar12[-1] = pdVar14[-1];
            pdVar12[-2] = dVar19;
            pdVar12 = pdVar12 + -2;
            pdVar14 = pdVar14 + -2;
          } while (pdVar14 != pdVar16);
          pdVar14 = (double *)*param_1;
          *param_1 = (double)pdVar12;
          param_1[1] = (double)pdVar18;
          param_1[2] = (double)pdVar11;
          if (pdVar14 != (double *)0x0) goto LAB_00316ae8;
        }
        else {
          if (uVar13 >> 0x3c != 0) {
            func_0x00108f70();
            goto LAB_00316b84;
          }
          pdVar6 = (double *)__Znwm(uVar13 << 4);
          pdVar12 = pdVar6 + lVar17 * 2;
          pdVar11 = pdVar6 + uVar13 * 2;
          *pdVar12 = dVar19;
          pdVar12[1] = dVar20;
          pdVar18 = pdVar12 + 2;
          if (pdVar14 != pdVar16) goto LAB_00316ab0;
LAB_00316ae0:
          *param_1 = (double)pdVar12;
          param_1[1] = (double)pdVar18;
          param_1[2] = (double)pdVar11;
LAB_00316ae8:
          pdVar6 = (double *)__ZdlPv(pdVar14);
        }
        pdVar14 = pdVar18;
        param_1[1] = (double)pdVar14;
        uVar15 = uVar15 + 1;
        if (uVar15 == uVar3) {
          return pdVar6;
        }
      } while( true );
    }
  }
  puVar7 = (undefined4 *)___cxa_allocate_exception(4);
  *puVar7 = 0xffffd505;
  uVar8 = ___cxa_throw(puVar7,&__ZTI15FilmCurveErrors,0);
  if (*unaff_x19 != 0) {
    unaff_x19[1] = *unaff_x19;
    __ZdlPv();
  }
  pdVar14 = (double *)__Unwind_Resume(uVar8);
  *pdVar14 = (double)&PTR___ZN10CaptureOne4Heif10HeifLoggerD1Ev_01ddf710;
  func_0x00316cd4(pdVar14 + 4,pdVar14[5]);
  if (*(char *)((long)pdVar14 + 0x1f) < '\0') {
    __ZdlPv(pdVar14[1]);
    return pdVar14;
  }
  return pdVar14;
}


/* _IC_GetDefaultProcessSettings @ 0119f1d0 */

undefined8 _IC_GetDefaultProcessSettings(long param_1,undefined8 param_2,int param_3)

{
  ulong uVar1;
  long *plVar2;
  code *pcVar3;
  int iVar4;
  long lVar5;
  ulong uVar6;
  undefined8 *******pppppppuVar7;
  long lVar8;
  undefined8 uVar9;
  undefined8 uVar10;
  undefined1 auVar11 [16];
  undefined8 ******ppppppuStack_180;
  ulong uStack_178;
  undefined8 uStack_170;
  long lStack_168;
  long *plStack_160;
  undefined1 auStack_158 [16];
  long lStack_148;
  long lStack_f8;
  long *plStack_f0;
  undefined1 auStack_e8 [16];
  long lStack_d8;
  long lStack_98;
  long *plStack_90;
  undefined1 auStack_88 [16];
  long lStack_78;
  undefined8 uStack_68;
  undefined1 *puStack_60;
  undefined8 uStack_58;
  char *pcStack_50;
  long lStack_48;
  long *plStack_40;
  undefined1 auStack_38 [16];
  long lStack_28;

  lStack_28 = *(long *)PTR____stack_chk_guard_01d15188;
  func_0x011cae04(auStack_38,"IC_GetDefaultProcessSettings");
  func_0x010fa3cc(&lStack_48);
  if (lStack_48 == 0) {
    pcStack_50 = "IC_GetDefaultProcessSettings";
    func_0x00574408("ImgCore not initialized [%s].");
    uVar9 = 5;
    plVar2 = plStack_40;
  }
  else if (param_1 == 0) {
    uVar9 = 4;
    plVar2 = plStack_40;
  }
  else {
    func_0x010c84e0(param_1);
    uVar9 = 0;
    plVar2 = plStack_40;
  }
  if (plVar2 != (long *)0x0) {
    LOAcquire();
    lVar5 = plVar2[1];
    plVar2[1] = lVar5 + -1;
    LORelease();
    if (lVar5 == 0) {
      (**(code **)(*plVar2 + 0x10))(plVar2);
      __ZNSt3__119__shared_weak_count14__release_weakEv(plVar2);
    }
  }
  func_0x011cb554(auStack_38);
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_28) {
    return uVar9;
  }
  uVar9 = ___stack_chk_fail();
  func_0x002431f8(&lStack_48);
  func_0x011cb554(auStack_38);
  __Unwind_Resume(uVar9);
  lVar5 = __Unwind_Resume();
  uStack_58 = 0x119f2e0;
  lStack_78 = *(long *)PTR____stack_chk_guard_01d15188;
  uStack_68 = uVar9;
  puStack_60 = &stack0xfffffffffffffff0;
  func_0x011cae04(auStack_88,"IC_GetDefaultImageProcessSettings");
  func_0x010fa3cc(&lStack_98);
  if (lStack_98 == 0) {
    func_0x00574408("ImgCore not initialized [%s].");
    uVar9 = 5;
    plVar2 = plStack_90;
  }
  else if (lVar5 == 0) {
    uVar9 = 4;
    plVar2 = plStack_90;
  }
  else {
    func_0x010c83a0(lVar5);
    uVar9 = 0;
    plVar2 = plStack_90;
  }
  if (plVar2 != (long *)0x0) {
    LOAcquire();
    lVar5 = plVar2[1];
    plVar2[1] = lVar5 + -1;
    LORelease();
    if (lVar5 == 0) {
      (**(code **)(*plVar2 + 0x10))(plVar2);
      __ZNSt3__119__shared_weak_count14__release_weakEv(plVar2);
    }
  }
  func_0x011cb554(auStack_88);
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_78) {
    return uVar9;
  }
  uVar9 = ___stack_chk_fail();
  func_0x002431f8(&lStack_98);
  func_0x011cb554(auStack_88);
  __Unwind_Resume(uVar9);
  auVar11 = __Unwind_Resume();
  lStack_d8 = *(long *)PTR____stack_chk_guard_01d15188;
  func_0x011cae04(auStack_e8,"IC_GetDefaultCameraProcessSettings");
  func_0x010fa3cc(&lStack_f8);
  if (lStack_f8 == 0) {
    func_0x00574408("ImgCore not initialized [%s].");
    uVar9 = 5;
    plVar2 = plStack_f0;
  }
  else if (auVar11._0_8_ == 0) {
    uVar9 = 9;
    plVar2 = plStack_f0;
  }
  else {
    param_3 = *(int *)(&UNK_0000ec0c + auVar11._8_8_);
    uVar9 = func_0x011418a8(*(undefined8 *)(lStack_f8 + 0x10),auVar11._0_8_,param_3,auVar11._8_8_,0)
    ;
    plVar2 = plStack_f0;
  }
  if (plVar2 != (long *)0x0) {
    LOAcquire();
    lVar5 = plVar2[1];
    plVar2[1] = lVar5 + -1;
    LORelease();
    if (lVar5 == 0) {
      (**(code **)(*plVar2 + 0x10))(plVar2);
      __ZNSt3__119__shared_weak_count14__release_weakEv(plVar2);
    }
  }
  func_0x011cb554(auStack_e8);
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_d8) {
    return uVar9;
  }
  uVar9 = ___stack_chk_fail();
  func_0x002431f8(&lStack_f8);
  func_0x011cb554(auStack_e8);
  __Unwind_Resume(uVar9);
  auVar11 = __Unwind_Resume();
  lVar8 = auVar11._8_8_;
  lStack_148 = *(long *)PTR____stack_chk_guard_01d15188;
  func_0x011cae04(auStack_158,"IC_ProxyReadyRef");
  func_0x010fa3cc(&lStack_168);
  lVar5 = lStack_168;
  if (lStack_168 == 0) {
    func_0x00574408("ImgCore not initialized [%s].");
    uVar9 = 5;
  }
  else if (lVar8 == 0) {
    uVar9 = 1;
  }
  else {
    func_0x00574208("IC_ProxyReadyRef: proxy = [%s]");
    uVar10 = *(undefined8 *)(lVar5 + 0x10);
    uVar9 = func_0x01135184(uVar10,auVar11._0_8_);
    iVar4 = func_0x01136cb8(uVar10,uVar9,lVar8);
    if (iVar4 == 0) {
      uVar9 = 0;
    }
    else {
      uVar9 = func_0x01136a84(*(undefined8 *)(lVar5 + 0x10),lVar8,0,0);
      if ((int)uVar9 == 0x14) {
        func_0x00574348("Invalid proxy detected [%s]");
        uVar9 = 0x14;
      }
      else {
        if ((param_3 != 0) && ((int)uVar9 == 0)) {
          uVar6 = _strlen(lVar8);
          if (0x7ffffffffffffff7 < uVar6) goto LAB_0119f784;
          if (uVar6 < 0x17) {
            uStack_170 = CONCAT17((char)uVar6,(undefined7)uStack_170);
            pppppppuVar7 = &ppppppuStack_180;
            if (uVar6 != 0) goto LAB_0119f67c;
          }
          else {
            uVar1 = (uVar6 & 0xfffffffffffffff8) + 8;
            if ((uVar6 | 7) != 0x17) {
              uVar1 = uVar6 | 7;
            }
            pppppppuVar7 = (undefined8 *******)__Znwm(uVar1 + 1);
            uStack_170 = uVar1 + 1 | 0x8000000000000000;
            ppppppuStack_180 = pppppppuVar7;
            uStack_178 = uVar6;
LAB_0119f67c:
            _memcpy(pppppppuVar7,lVar8,uVar6);
          }
          *(undefined1 *)((long)pppppppuVar7 + uVar6) = 0;
          lVar5 = (long)ppppppuStack_180 + uStack_178;
          pppppppuVar7 = (undefined8 *******)ppppppuStack_180;
          if (-1 < (long)uStack_170) {
            lVar5 = (long)&ppppppuStack_180 + (uStack_170 >> 0x38);
            pppppppuVar7 = &ppppppuStack_180;
          }
          __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE7replaceEmmPKcm
                    (&ppppppuStack_180,(lVar5 - (long)pppppppuVar7) + -3,3,"cof",3);
          pppppppuVar7 = (undefined8 *******)ppppppuStack_180;
          if (-1 < (long)uStack_170) {
            pppppppuVar7 = &ppppppuStack_180;
          }
          uVar9 = func_0x01136e50(*(undefined8 *)(lStack_168 + 0x10),pppppppuVar7);
          if ((long)uStack_170 < 0) {
            __ZdlPv(ppppppuStack_180);
          }
        }
        func_0x00574208("IC_ProxyReadyRef (completed): proxy = [%s]");
      }
    }
  }
  if (plStack_160 != (long *)0x0) {
    LOAcquire();
    lVar5 = plStack_160[1];
    plStack_160[1] = lVar5 + -1;
    LORelease();
    if (lVar5 == 0) {
      (**(code **)(*plStack_160 + 0x10))(plStack_160);
      __ZNSt3__119__shared_weak_count14__release_weakEv(plStack_160);
    }
  }
  func_0x011cb554(auStack_158);
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_148) {
    return uVar9;
  }
  ___stack_chk_fail();
LAB_0119f784:
  func_0x00108f98(&ppppppuStack_180);
                    /* WARNING: Does not return */
  pcVar3 = (code *)SoftwareBreakpoint(1,0x119f790);
  (*pcVar3)();
}


/* _IC_GetDefaultImageProcessSettings @ 0119f2e0 */

undefined8 _IC_GetDefaultImageProcessSettings(long param_1,undefined8 param_2,int param_3)

{
  ulong uVar1;
  long *plVar2;
  code *pcVar3;
  long lVar4;
  int iVar5;
  ulong uVar6;
  undefined8 *******pppppppuVar7;
  long lVar8;
  undefined8 uVar9;
  undefined8 uVar10;
  undefined1 auVar11 [16];
  undefined8 ******ppppppuStack_130;
  ulong uStack_128;
  undefined8 uStack_120;
  long lStack_118;
  long *plStack_110;
  undefined1 auStack_108 [16];
  long lStack_f8;
  long lStack_a8;
  long *plStack_a0;
  undefined1 auStack_98 [16];
  long lStack_88;
  long lStack_48;
  long *plStack_40;
  undefined1 auStack_38 [16];
  long lStack_28;

  lStack_28 = *(long *)PTR____stack_chk_guard_01d15188;
  func_0x011cae04(auStack_38,"IC_GetDefaultImageProcessSettings");
  func_0x010fa3cc(&lStack_48);
  if (lStack_48 == 0) {
    func_0x00574408("ImgCore not initialized [%s].");
    uVar9 = 5;
    plVar2 = plStack_40;
  }
  else if (param_1 == 0) {
    uVar9 = 4;
    plVar2 = plStack_40;
  }
  else {
    func_0x010c83a0(param_1);
    uVar9 = 0;
    plVar2 = plStack_40;
  }
  if (plVar2 != (long *)0x0) {
    LOAcquire();
    lVar4 = plVar2[1];
    plVar2[1] = lVar4 + -1;
    LORelease();
    if (lVar4 == 0) {
      (**(code **)(*plVar2 + 0x10))(plVar2);
      __ZNSt3__119__shared_weak_count14__release_weakEv(plVar2);
    }
  }
  func_0x011cb554(auStack_38);
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_28) {
    return uVar9;
  }
  uVar9 = ___stack_chk_fail();
  func_0x002431f8(&lStack_48);
  func_0x011cb554(auStack_38);
  __Unwind_Resume(uVar9);
  auVar11 = __Unwind_Resume();
  lStack_88 = *(long *)PTR____stack_chk_guard_01d15188;
  func_0x011cae04(auStack_98,"IC_GetDefaultCameraProcessSettings");
  func_0x010fa3cc(&lStack_a8);
  if (lStack_a8 == 0) {
    func_0x00574408("ImgCore not initialized [%s].");
    uVar9 = 5;
    plVar2 = plStack_a0;
  }
  else if (auVar11._0_8_ == 0) {
    uVar9 = 9;
    plVar2 = plStack_a0;
  }
  else {
    param_3 = *(int *)(&UNK_0000ec0c + auVar11._8_8_);
    uVar9 = func_0x011418a8(*(undefined8 *)(lStack_a8 + 0x10),auVar11._0_8_,param_3,auVar11._8_8_,0)
    ;
    plVar2 = plStack_a0;
  }
  if (plVar2 != (long *)0x0) {
    LOAcquire();
    lVar4 = plVar2[1];
    plVar2[1] = lVar4 + -1;
    LORelease();
    if (lVar4 == 0) {
      (**(code **)(*plVar2 + 0x10))(plVar2);
      __ZNSt3__119__shared_weak_count14__release_weakEv(plVar2);
    }
  }
  func_0x011cb554(auStack_98);
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_88) {
    return uVar9;
  }
  uVar9 = ___stack_chk_fail();
  func_0x002431f8(&lStack_a8);
  func_0x011cb554(auStack_98);
  __Unwind_Resume(uVar9);
  auVar11 = __Unwind_Resume();
  lVar8 = auVar11._8_8_;
  lStack_f8 = *(long *)PTR____stack_chk_guard_01d15188;
  func_0x011cae04(auStack_108,"IC_ProxyReadyRef");
  func_0x010fa3cc(&lStack_118);
  lVar4 = lStack_118;
  if (lStack_118 == 0) {
    func_0x00574408("ImgCore not initialized [%s].");
    uVar9 = 5;
  }
  else if (lVar8 == 0) {
    uVar9 = 1;
  }
  else {
    func_0x00574208("IC_ProxyReadyRef: proxy = [%s]");
    uVar10 = *(undefined8 *)(lVar4 + 0x10);
    uVar9 = func_0x01135184(uVar10,auVar11._0_8_);
    iVar5 = func_0x01136cb8(uVar10,uVar9,lVar8);
    if (iVar5 == 0) {
      uVar9 = 0;
    }
    else {
      uVar9 = func_0x01136a84(*(undefined8 *)(lVar4 + 0x10),lVar8,0,0);
      if ((int)uVar9 == 0x14) {
        func_0x00574348("Invalid proxy detected [%s]");
        uVar9 = 0x14;
      }
      else {
        if ((param_3 != 0) && ((int)uVar9 == 0)) {
          uVar6 = _strlen(lVar8);
          if (0x7ffffffffffffff7 < uVar6) goto LAB_0119f784;
          if (uVar6 < 0x17) {
            uStack_120 = CONCAT17((char)uVar6,(undefined7)uStack_120);
            pppppppuVar7 = &ppppppuStack_130;
            if (uVar6 != 0) goto LAB_0119f67c;
          }
          else {
            uVar1 = (uVar6 & 0xfffffffffffffff8) + 8;
            if ((uVar6 | 7) != 0x17) {
              uVar1 = uVar6 | 7;
            }
            pppppppuVar7 = (undefined8 *******)__Znwm(uVar1 + 1);
            uStack_120 = uVar1 + 1 | 0x8000000000000000;
            ppppppuStack_130 = pppppppuVar7;
            uStack_128 = uVar6;
LAB_0119f67c:
            _memcpy(pppppppuVar7,lVar8,uVar6);
          }
          *(undefined1 *)((long)pppppppuVar7 + uVar6) = 0;
          lVar4 = (long)ppppppuStack_130 + uStack_128;
          pppppppuVar7 = (undefined8 *******)ppppppuStack_130;
          if (-1 < (long)uStack_120) {
            lVar4 = (long)&ppppppuStack_130 + (uStack_120 >> 0x38);
            pppppppuVar7 = &ppppppuStack_130;
          }
          __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE7replaceEmmPKcm
                    (&ppppppuStack_130,(lVar4 - (long)pppppppuVar7) + -3,3,"cof",3);
          pppppppuVar7 = (undefined8 *******)ppppppuStack_130;
          if (-1 < (long)uStack_120) {
            pppppppuVar7 = &ppppppuStack_130;
          }
          uVar9 = func_0x01136e50(*(undefined8 *)(lStack_118 + 0x10),pppppppuVar7);
          if ((long)uStack_120 < 0) {
            __ZdlPv(ppppppuStack_130);
          }
        }
        func_0x00574208("IC_ProxyReadyRef (completed): proxy = [%s]");
      }
    }
  }
  if (plStack_110 != (long *)0x0) {
    LOAcquire();
    lVar4 = plStack_110[1];
    plStack_110[1] = lVar4 + -1;
    LORelease();
    if (lVar4 == 0) {
      (**(code **)(*plStack_110 + 0x10))(plStack_110);
      __ZNSt3__119__shared_weak_count14__release_weakEv(plStack_110);
    }
  }
  func_0x011cb554(auStack_108);
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_f8) {
    return uVar9;
  }
  ___stack_chk_fail();
LAB_0119f784:
  func_0x00108f98(&ppppppuStack_130);
                    /* WARNING: Does not return */
  pcVar3 = (code *)SoftwareBreakpoint(1,0x119f790);
  (*pcVar3)();
}


/* _IC_GetDefaultCameraProcessSettings @ 0119f3f0 */

undefined8 _IC_GetDefaultCameraProcessSettings(long param_1,long param_2,int param_3)

{
  ulong uVar1;
  long *plVar2;
  code *pcVar3;
  long lVar4;
  int iVar5;
  undefined8 uVar6;
  ulong uVar7;
  undefined8 *******pppppppuVar8;
  long lVar9;
  undefined8 uVar10;
  undefined1 auVar11 [16];
  undefined8 ******ppppppuStack_e0;
  ulong uStack_d8;
  undefined8 uStack_d0;
  long lStack_c8;
  long *plStack_c0;
  undefined1 auStack_b8 [16];
  long lStack_a8;
  long lStack_58;
  long *plStack_50;
  undefined1 auStack_48 [16];
  long lStack_38;

  lStack_38 = *(long *)PTR____stack_chk_guard_01d15188;
  func_0x011cae04(auStack_48,"IC_GetDefaultCameraProcessSettings");
  func_0x010fa3cc(&lStack_58);
  if (lStack_58 == 0) {
    func_0x00574408("ImgCore not initialized [%s].");
    uVar6 = 5;
    plVar2 = plStack_50;
  }
  else if (param_1 == 0) {
    uVar6 = 9;
    plVar2 = plStack_50;
  }
  else {
    param_3 = *(int *)(&UNK_0000ec0c + param_2);
    uVar6 = func_0x011418a8(*(undefined8 *)(lStack_58 + 0x10),param_1,param_3,param_2,0);
    plVar2 = plStack_50;
  }
  if (plVar2 != (long *)0x0) {
    LOAcquire();
    lVar4 = plVar2[1];
    plVar2[1] = lVar4 + -1;
    LORelease();
    if (lVar4 == 0) {
      (**(code **)(*plVar2 + 0x10))(plVar2);
      __ZNSt3__119__shared_weak_count14__release_weakEv(plVar2);
    }
  }
  func_0x011cb554(auStack_48);
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_38) {
    return uVar6;
  }
  uVar6 = ___stack_chk_fail();
  func_0x002431f8(&lStack_58);
  func_0x011cb554(auStack_48);
  __Unwind_Resume(uVar6);
  auVar11 = __Unwind_Resume();
  lVar9 = auVar11._8_8_;
  lStack_a8 = *(long *)PTR____stack_chk_guard_01d15188;
  func_0x011cae04(auStack_b8,"IC_ProxyReadyRef");
  func_0x010fa3cc(&lStack_c8);
  lVar4 = lStack_c8;
  if (lStack_c8 == 0) {
    func_0x00574408("ImgCore not initialized [%s].");
    uVar6 = 5;
  }
  else if (lVar9 == 0) {
    uVar6 = 1;
  }
  else {
    func_0x00574208("IC_ProxyReadyRef: proxy = [%s]");
    uVar10 = *(undefined8 *)(lVar4 + 0x10);
    uVar6 = func_0x01135184(uVar10,auVar11._0_8_);
    iVar5 = func_0x01136cb8(uVar10,uVar6,lVar9);
    if (iVar5 == 0) {
      uVar6 = 0;
    }
    else {
      uVar6 = func_0x01136a84(*(undefined8 *)(lVar4 + 0x10),lVar9,0,0);
      if ((int)uVar6 == 0x14) {
        func_0x00574348("Invalid proxy detected [%s]");
        uVar6 = 0x14;
      }
      else {
        if ((param_3 != 0) && ((int)uVar6 == 0)) {
          uVar7 = _strlen(lVar9);
          if (0x7ffffffffffffff7 < uVar7) goto LAB_0119f784;
          if (uVar7 < 0x17) {
            uStack_d0 = CONCAT17((char)uVar7,(undefined7)uStack_d0);
            pppppppuVar8 = &ppppppuStack_e0;
            if (uVar7 != 0) goto LAB_0119f67c;
          }
          else {
            uVar1 = (uVar7 & 0xfffffffffffffff8) + 8;
            if ((uVar7 | 7) != 0x17) {
              uVar1 = uVar7 | 7;
            }
            pppppppuVar8 = (undefined8 *******)__Znwm(uVar1 + 1);
            uStack_d0 = uVar1 + 1 | 0x8000000000000000;
            ppppppuStack_e0 = pppppppuVar8;
            uStack_d8 = uVar7;
LAB_0119f67c:
            _memcpy(pppppppuVar8,lVar9,uVar7);
          }
          *(undefined1 *)((long)pppppppuVar8 + uVar7) = 0;
          lVar4 = (long)ppppppuStack_e0 + uStack_d8;
          pppppppuVar8 = (undefined8 *******)ppppppuStack_e0;
          if (-1 < (long)uStack_d0) {
            lVar4 = (long)&ppppppuStack_e0 + (uStack_d0 >> 0x38);
            pppppppuVar8 = &ppppppuStack_e0;
          }
          __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE7replaceEmmPKcm
                    (&ppppppuStack_e0,(lVar4 - (long)pppppppuVar8) + -3,3,"cof",3);
          pppppppuVar8 = (undefined8 *******)ppppppuStack_e0;
          if (-1 < (long)uStack_d0) {
            pppppppuVar8 = &ppppppuStack_e0;
          }
          uVar6 = func_0x01136e50(*(undefined8 *)(lStack_c8 + 0x10),pppppppuVar8);
          if ((long)uStack_d0 < 0) {
            __ZdlPv(ppppppuStack_e0);
          }
        }
        func_0x00574208("IC_ProxyReadyRef (completed): proxy = [%s]");
      }
    }
  }
  if (plStack_c0 != (long *)0x0) {
    LOAcquire();
    lVar4 = plStack_c0[1];
    plStack_c0[1] = lVar4 + -1;
    LORelease();
    if (lVar4 == 0) {
      (**(code **)(*plStack_c0 + 0x10))(plStack_c0);
      __ZNSt3__119__shared_weak_count14__release_weakEv(plStack_c0);
    }
  }
  func_0x011cb554(auStack_b8);
  if (*(long *)PTR____stack_chk_guard_01d15188 == lStack_a8) {
    return uVar6;
  }
  ___stack_chk_fail();
LAB_0119f784:
  func_0x00108f98(&ppppppuStack_e0);
                    /* WARNING: Does not return */
  pcVar3 = (code *)SoftwareBreakpoint(1,0x119f790);
  (*pcVar3)();
}


/* _POGradationCurveGetNumberOfPoints @ 01555efc */

int _POGradationCurveGetNumberOfPoints(long param_1)

{
  int iVar1;

  iVar1 = 0;
  if (param_1 != 0) {
    iVar1 = (int)((ulong)(*(long *)(param_1 + 0x18) - *(long *)(param_1 + 0x10)) >> 4) * -0x55555555
    ;
  }
  return iVar1;
}


/* _POGradationCurveGetXAtIndex @ 01555f1c */

undefined1  [16] _POGradationCurveGetXAtIndex(long param_1,uint param_2)

{
  ulong uVar1;
  undefined1 auVar2 [16];
  undefined1 auVar3 [16];

  if (param_1 == 0) {
    uVar1 = 0;
  }
  else {
    uVar1 = 0xbff0000000000000;
    if (param_2 < (uint)((int)((ulong)(*(long *)(param_1 + 0x18) - *(long *)(param_1 + 0x10)) >> 4)
                        * -0x55555555)) {
      auVar2._0_8_ = *(ulong *)(*(long *)(param_1 + 0x10) + (ulong)param_2 * 0x30);
      auVar2._8_8_ = 0;
      return auVar2;
    }
  }
  auVar3._8_8_ = 0;
  auVar3._0_8_ = uVar1;
  return auVar3;
}


/* _POGradationCurveGetYAtIndex @ 01555f5c */

undefined1  [16] _POGradationCurveGetYAtIndex(long param_1,uint param_2)

{
  ulong uVar1;
  undefined1 auVar2 [16];
  undefined1 auVar3 [16];

  if (param_1 == 0) {
    uVar1 = 0;
  }
  else {
    uVar1 = 0xbff0000000000000;
    if (param_2 < (uint)((int)((ulong)(*(long *)(param_1 + 0x18) - *(long *)(param_1 + 0x10)) >> 4)
                        * -0x55555555)) {
      auVar2._0_8_ = *(ulong *)(*(long *)(param_1 + 0x10) + (ulong)param_2 * 0x30 + 8);
      auVar2._8_8_ = 0;
      return auVar2;
    }
  }
  auVar3._8_8_ = 0;
  auVar3._0_8_ = uVar1;
  return auVar3;
}
