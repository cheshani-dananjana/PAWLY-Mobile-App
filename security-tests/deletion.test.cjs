
const fs = require("node:fs");
const path = require("node:path");

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");

const {
  doc,
  collection,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  writeBatch,
  serverTimestamp,
} = require("firebase/firestore");

async function runTests() {
  const env = await initializeTestEnvironment({
    projectId: "demo-pawly-test",
    firestore: {
      host: "127.0.0.1",
      port: 8081,
      rules: fs.readFileSync(
        path.join(__dirname, "../firestore.rules"),
        "utf8"
      ),
    },
  });

  const prefix = `deletion_test_${Date.now()}_`;

  const adminId = prefix + "admin";
  const userId = prefix + "user";
  const otherId = prefix + "other";
  const admin2Id = prefix + "admin2";
  const reportId = prefix + "report";

  try {
    // Create isolated test profiles.
    // Existing emulator data is not cleared.

    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      for (const [uid, role] of [
        [adminId, "admin"],
        [userId, "user"],
        [otherId, "user"],
        [admin2Id, "admin"],
      ]) {
        await setDoc(doc(db, "users", uid), {
          uid,
          full_name: uid,
          email: `${uid}@example.com`,
          role,
          account_status: "active",
        });
      }

      await setDoc(doc(db, "post_reports", reportId), {
        postId: prefix + "post",
        reporterId: otherId,
        reportedUserId: userId,
        reason: "Animal welfare concern",
        description: "Deletion security test",
        status: "pending",
        createdAt: serverTimestamp(),
        resolvedAt: null,
        resolvedBy: null,
      });
    });

    const admin = env
      .authenticatedContext(adminId)
      .firestore();

    const user = env
      .authenticatedContext(userId)
      .firestore();

    const guest = env
      .unauthenticatedContext()
      .firestore();

    function requestData(uid, requester, report) {
      return {
        userId: uid,
        reportId: report,
        requestedBy: requester,
        reason: "Reported account requires review.",
        status: "pending",
        createdAt: serverTimestamp(),
      };
    }

    function submitRequest(
      db,
      uid,
      requester,
      report
    ) {
      const batch = writeBatch(db);

      batch.set(
        doc(db, "deletion_requests", uid),
        requestData(uid, requester, report)
      );

      batch.update(doc(db, "users", uid), {
        account_status: "disabled",
      });

      return batch.commit();
    }

    // TEST 01

    await assertFails(
      submitRequest(user, userId, userId, reportId)
    );

    console.log("PASS 01: Normal user blocked");

    // TEST 02

    await assertFails(
      setDoc(
        doc(guest, "deletion_requests", userId),
        requestData(userId, adminId, reportId)
      )
    );

    console.log("PASS 02: Guest blocked");

    // TEST 03

    await assertFails(
      submitRequest(admin, adminId, adminId, reportId)
    );

    console.log("PASS 03: Own admin account protected");

    // TEST 04

    await assertFails(
      submitRequest(admin, admin2Id, adminId, reportId)
    );

    console.log("PASS 04: Other admin account protected");

    // TEST 05

    await assertFails(
      submitRequest(admin, otherId, adminId, reportId)
    );

    console.log("PASS 05: Incorrect reported user blocked");

    // TEST 06

    await assertFails(
      submitRequest(
        admin,
        userId,
        adminId,
        "missing_report"
      )
    );

    console.log("PASS 06: Invalid report blocked");

    // TEST 07

    await assertFails(
      setDoc(
        doc(admin, "deletion_requests", userId),
        requestData(userId, adminId, reportId)
      )
    );

    console.log("PASS 07: Request without disabling blocked");

    // TEST 08

    await assertSucceeds(
      submitRequest(admin, userId, adminId, reportId)
    );

    console.log("PASS 08: Valid deletion request created");

    // TEST 09

    const profile = await getDoc(
      doc(admin, "users", userId)
    );

    if (profile.data().account_status !== "disabled") {
      throw new Error("User account was not disabled");
    }

    console.log("PASS 09: Account automatically disabled");

    // TEST 10

    await assertFails(
      submitRequest(admin, userId, adminId, reportId)
    );

    console.log("PASS 10: Duplicate request blocked");

    // TEST 11

    await assertFails(
      updateDoc(doc(admin, "users", userId), {
        account_status: "active",
      })
    );

    console.log("PASS 11: Pending deletion reactivation blocked");

    // TEST 12

    await assertSucceeds(
      getDocs(collection(admin, "deletion_requests"))
    );

    console.log("PASS 12: Admin can view deletion requests");

    // TEST 13

    await assertFails(
      getDoc(doc(user, "deletion_requests", userId))
    );

    console.log("PASS 13: Request privacy protected");

    // TEST 14

    await assertFails(
      updateDoc(
        doc(admin, "deletion_requests", userId),
        { status: "completed" }
      )
    );

    console.log("PASS 14: Unauthorized completion blocked");

    // TEST 15

    await assertFails(
      deleteDoc(doc(admin, "deletion_requests", userId))
    );

    console.log("PASS 15: Audit record protected");

    // TEST 16

    await assertFails(
      deleteDoc(doc(admin, "users", userId))
    );

    console.log("PASS 16: Direct user deletion blocked");

    console.log(
      "\nALL 16 DELETION SECURITY TESTS PASSED!"
    );

  } finally {

    // Remove only documents created by this test.

    try {
      await env.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();

        for (const uid of [
          adminId,
          userId,
          otherId,
          admin2Id,
        ]) {
          await deleteDoc(doc(db, "users", uid));
          await deleteDoc(doc(db, "deletion_requests", uid));
        }

        await deleteDoc(doc(db, "post_reports", reportId));
      });
    } finally {
      await env.cleanup();
    }
  }
}

runTests().catch((error) => {
  console.error("TEST FAILED:", error);
  process.exitCode = 1;
});
