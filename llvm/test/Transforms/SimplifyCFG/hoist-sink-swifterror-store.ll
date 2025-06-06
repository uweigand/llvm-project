; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 2
; RUN: opt -passes='simplifycfg<sink-common-insts;hoist-common-insts>,verify' -S %s | FileCheck %s

declare void @clobber1()
declare void @clobber2()
declare swiftcc void @foo(ptr swifterror)
declare swiftcc void @bar(ptr swifterror, ptr)

; Do not try to sink the stores to the exit block, as this requires introducing
; a select for the pointer operand. This is not allowed for swifterror pointers.
define swiftcc void @sink(ptr %arg, ptr swifterror %arg1, i1 %c) {
; CHECK-LABEL: define swiftcc void @sink
; CHECK-SAME: (ptr [[ARG:%.*]], ptr swifterror [[ARG1:%.*]], i1 [[C:%.*]]) {
; CHECK-NEXT:  bb:
; CHECK-NEXT:    br i1 [[C]], label [[THEN:%.*]], label [[ELSE:%.*]]
; CHECK:       then:
; CHECK-NEXT:    call void @clobber1()
; CHECK-NEXT:    store ptr null, ptr [[ARG]], align 8
; CHECK-NEXT:    br label [[EXIT:%.*]]
; CHECK:       else:
; CHECK-NEXT:    call void @clobber2()
; CHECK-NEXT:    store ptr null, ptr [[ARG1]], align 8
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
bb:
  br i1 %c, label %then, label %else

then:
  call void @clobber1()
  store ptr null, ptr %arg, align 8
  br label %exit

else:
  call void @clobber2()
  store ptr null, ptr %arg1, align 8
  br label %exit

exit:
  ret void
}

define swiftcc void @hoist_store(ptr %arg, ptr swifterror %arg1, i1 %c) {
; CHECK-LABEL: define swiftcc void @hoist_store
; CHECK-SAME: (ptr [[ARG:%.*]], ptr swifterror [[ARG1:%.*]], i1 [[C:%.*]]) {
; CHECK-NEXT:  bb:
; CHECK-NEXT:    br i1 [[C]], label [[THEN:%.*]], label [[ELSE:%.*]]
; CHECK:       then:
; CHECK-NEXT:    store ptr null, ptr [[ARG]], align 8
; CHECK-NEXT:    call void @clobber1()
; CHECK-NEXT:    br label [[EXIT:%.*]]
; CHECK:       else:
; CHECK-NEXT:    store ptr null, ptr [[ARG1]], align 8
; CHECK-NEXT:    call void @clobber2()
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
bb:
  br i1 %c, label %then, label %else

then:
  store ptr null, ptr %arg, align 8
  call void @clobber1()
  br label %exit

else:
  store ptr null, ptr %arg1, align 8
  call void @clobber2()
  br label %exit

exit:
  ret void
}

; FIXME: currently simplifycfg tries to sink the load to the exit block and
; introduces a select for the pointer operand. This is not allowed for
; swifterror pointers.
define swiftcc ptr @sink_load(ptr %arg, ptr swifterror %arg1, i1 %c) {
; CHECK-LABEL: define swiftcc ptr @sink_load
; CHECK-SAME: (ptr [[ARG:%.*]], ptr swifterror [[ARG1:%.*]], i1 [[C:%.*]]) {
; CHECK-NEXT:  bb:
; CHECK-NEXT:    br i1 [[C]], label [[THEN:%.*]], label [[ELSE:%.*]]
; CHECK:       then:
; CHECK-NEXT:    call void @clobber1()
; CHECK-NEXT:    [[L1:%.*]] = load ptr, ptr [[ARG]], align 8
; CHECK-NEXT:    br label [[EXIT:%.*]]
; CHECK:       else:
; CHECK-NEXT:    call void @clobber2()
; CHECK-NEXT:    [[L2:%.*]] = load ptr, ptr [[ARG1]], align 8
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    [[P:%.*]] = phi ptr [ [[L1]], [[THEN]] ], [ [[L2]], [[ELSE]] ]
; CHECK-NEXT:    ret ptr [[P]]
;
bb:
  br i1 %c, label %then, label %else

then:
  call void @clobber1()
  %l1 = load ptr, ptr %arg, align 8
  br label %exit

else:
  call void @clobber2()
  %l2 = load ptr, ptr %arg1, align 8
  br label %exit

exit:
  %p = phi ptr [ %l1, %then ], [ %l2, %else ]
  ret ptr %p
}
define swiftcc ptr @hoist_load(ptr %arg, ptr swifterror %arg1, i1 %c) {
; CHECK-LABEL: define swiftcc ptr @hoist_load
; CHECK-SAME: (ptr [[ARG:%.*]], ptr swifterror [[ARG1:%.*]], i1 [[C:%.*]]) {
; CHECK-NEXT:  bb:
; CHECK-NEXT:    br i1 [[C]], label [[THEN:%.*]], label [[ELSE:%.*]]
; CHECK:       then:
; CHECK-NEXT:    [[L1:%.*]] = load ptr, ptr [[ARG]], align 8
; CHECK-NEXT:    call void @clobber1()
; CHECK-NEXT:    br label [[EXIT:%.*]]
; CHECK:       else:
; CHECK-NEXT:    [[L2:%.*]] = load ptr, ptr [[ARG1]], align 8
; CHECK-NEXT:    call void @clobber2()
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    [[P:%.*]] = phi ptr [ [[L1]], [[THEN]] ], [ [[L2]], [[ELSE]] ]
; CHECK-NEXT:    ret ptr [[P]]
;
bb:
  br i1 %c, label %then, label %else

then:
  %l1 = load ptr, ptr %arg, align 8
  call void @clobber1()
  br label %exit

else:
  %l2 = load ptr, ptr %arg1, align 8
  call void @clobber2()
  br label %exit

exit:
  %p = phi ptr [ %l1, %then ], [ %l2, %else ]
  ret ptr %p
}


define swiftcc void @sink_call(i1 %c) {
; CHECK-LABEL: define swiftcc void @sink_call
; CHECK-SAME: (i1 [[C:%.*]]) {
; CHECK-NEXT:    [[TMP1:%.*]] = alloca swifterror ptr, align 8
; CHECK-NEXT:    [[TMP2:%.*]] = alloca swifterror ptr, align 8
; CHECK-NEXT:    br i1 [[C]], label [[THEN:%.*]], label [[ELSE:%.*]]
; CHECK:       then:
; CHECK-NEXT:    call void @clobber1()
; CHECK-NEXT:    call swiftcc void @foo(ptr [[TMP2]])
; CHECK-NEXT:    br label [[EXIT:%.*]]
; CHECK:       else:
; CHECK-NEXT:    call void @clobber2()
; CHECK-NEXT:    call swiftcc void @foo(ptr [[TMP1]])
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
  %2 = alloca swifterror ptr, align 8
  %3 = alloca swifterror ptr, align 8
  br i1 %c, label %then, label %else

then:
  call void @clobber1()
  call swiftcc void @foo(ptr %3)
  br label %exit

else:
  call void @clobber2()
  call swiftcc void @foo(ptr %2)
  br label %exit

exit:
  ret void
}


define swiftcc void @safe_sink_call(i1 %c) {
; CHECK-LABEL: define swiftcc void @safe_sink_call
; CHECK-SAME: (i1 [[C:%.*]]) {
; CHECK-NEXT:    [[ERR:%.*]] = alloca swifterror ptr, align 8
; CHECK-NEXT:    [[A:%.*]] = alloca ptr, align 8
; CHECK-NEXT:    [[B:%.*]] = alloca ptr, align 8
; CHECK-NEXT:    br i1 [[C]], label [[THEN:%.*]], label [[ELSE:%.*]]
; CHECK:       then:
; CHECK-NEXT:    call void @clobber1()
; CHECK-NEXT:    br label [[EXIT:%.*]]
; CHECK:       else:
; CHECK-NEXT:    call void @clobber2()
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    [[B_SINK:%.*]] = phi ptr [ [[B]], [[ELSE]] ], [ [[A]], [[THEN]] ]
; CHECK-NEXT:    call swiftcc void @bar(ptr [[ERR]], ptr [[B_SINK]])
; CHECK-NEXT:    ret void
;
  %err = alloca swifterror ptr, align 8
  %a = alloca ptr, align 8
  %b = alloca ptr, align 8
  br i1 %c, label %then, label %else

then:
  call void @clobber1()
  call swiftcc void @bar(ptr %err, ptr %a)
  br label %exit

else:
  call void @clobber2()
  call swiftcc void @bar(ptr %err, ptr %b)
  br label %exit

exit:
  ret void
}
