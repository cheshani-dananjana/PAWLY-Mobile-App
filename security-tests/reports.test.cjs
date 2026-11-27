
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

  try {
    // Clear local emulator data only
    await env.clearFirestore();

    // Create sample test data
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      const users = [
        ["admin1", "admin", "active"],
        ["admin2", "admin", "active"],
        ["user1", "user", "active"],
        ["user2", "user", "active"],
        ["banned1", "user", "banned"],
        ["disabled1", "user", "disabled"],
      ];

      for (const [uid, role, status] of users) {
        await setDoc(doc(db, "users", uid), {
          uid: uid,
          full_name: uid,
          email: `${uid}@example.com`,
          phone_number: "0770000000",
          role: role,
          account_status: status,
        });
      }

      await setDoc(doc(db, "posts", "post1"), {
        name: "Test Animal",
        userId: "user2",
      });
    });

    const admin = env
      .authenticatedContext("admin1")
      .firestore();

    const user = env
      .authenticatedContext("user1")
      .firestore();

    const otherUser = env
      .authenticatedContext("user2")
      .firestore();

    const banned = env
      .authenticatedContext("banned1")
      .firestore();

    const disabled = env
      .authenticatedContext("disabled1")
      .firestore();

    const guest = env
      .unauthenticatedContext()
      .firestore();

    function createReport(reporterId) {
      return {
        postId: "post1",
        reporterId: reporterId,
        reportedUserId: "user2",
        reason: "Misleading animal information",
        description: "Sample security test report.",
        status: "pending",
        createdAt: serverTimestamp(),
        resolvedAt: null,
        resolvedBy: null,
      };
    }

    // TEST 01
    await assertSucceeds(
      setDoc(
        doc(user, "post_reports", "report1"),
        createReport("user1")
      )
    );
    console.log("PASS 01: Active user can submit report");

    // TEST 02
    await assertFails(
      setDoc(
        doc(banned, "post_reports", "report2"),
        createReport("banned1")
      )
    );
    console.log("PASS 02: Banned user cannot report");

    // TEST 03
    await assertFails(
      setDoc(
        doc(disabled, "post_reports", "report3"),
        createReport("disabled1")
      )
    );
    console.log("PASS 03: Disabled user cannot report");

    // TEST 04
    await assertFails(
      setDoc(
        doc(guest, "post_reports", "report4"),
        createReport("guest")
      )
    );
    console.log("PASS 04: Guest cannot report");

    // TEST 05
    await assertFails(
      setDoc(
        doc(user, "post_reports", "report5"),
        createReport("user2")
      )
    );
    console.log("PASS 05: Fake reporter ID blocked");

    // TEST 06
    await assertSucceeds(
      getDocs(collection(admin, "post_reports"))
    );
    console.log("PASS 06: Admin can view all reports");

    // TEST 07
    await assertFails(
      getDocs(collection(user, "post_reports"))
    );
    console.log("PASS 07: Normal user cannot list reports");

    // TEST 08
    await assertSucceeds(
      getDoc(doc(user, "post_reports", "report1"))
    );
    console.log("PASS 08: User can read own report");

    // TEST 09
    await assertFails(
      getDoc(doc(otherUser, "post_reports", "report1"))
    );
    console.log("PASS 09: Other user report protected");

    // TEST 10
    await assertFails(
      updateDoc(
        doc(user, "post_reports", "report1"),
        {
          status: "resolved",
          resolvedAt: serverTimestamp(),
          resolvedBy: "user1",
        }
      )
    );
    console.log("PASS 10: Unauthorized resolution blocked");

    // TEST 11
    await assertSucceeds(
      updateDoc(
        doc(admin, "post_reports", "report1"),
        {
          status: "resolved",
          resolvedAt: serverTimestamp(),
          resolvedBy: "admin1",
        }
      )
    );
    console.log("PASS 11: Admin can resolve report");

    // TEST 12
    await assertSucceeds(
      setDoc(
        doc(user, "post_reports", "report6"),
        createReport("user1")
      )
    );

    await assertSucceeds(
      updateDoc(
        doc(admin, "post_reports", "report6"),
        {
          status: "dismissed",
          resolvedAt: serverTimestamp(),
          resolvedBy: "admin1",
        }
      )
    );
    console.log("PASS 12: Admin can dismiss report");

    // TEST 13
    await assertFails(
      updateDoc(
        doc(admin, "post_reports", "report1"),
        {
          status: "dismissed",
          resolvedAt: serverTimestamp(),
          resolvedBy: "admin1",
        }
      )
    );
    console.log("PASS 13: Reviewed report protected");

    // TEST 14
    await assertFails(
      deleteDoc(doc(admin, "post_reports", "report1"))
    );
    console.log("PASS 14: Direct report deletion blocked");

    // TEST 15
    await assertFails(
      updateDoc(doc(admin, "users", "admin2"), {
        account_status: "banned",
      })
    );
    console.log("PASS 15: Other admin account protected");

    // TEST 16
    await assertFails(
      updateDoc(doc(admin, "users", "admin1"), {
        account_status: "disabled",
      })
    );
    console.log("PASS 16: Own admin account protected");

    // TEST 17
    await assertFails(
      updateDoc(doc(admin, "users", "user2"), {
        role: "admin",
      })
    );
    console.log("PASS 17: Unauthorized role change blocked");

    // TEST 18
    await assertSucceeds(
      updateDoc(doc(admin, "users", "user2"), {
        account_status: "banned",
      })
    );
    console.log("PASS 18: Admin can ban reported user");

    // TEST 19
    await assertSucceeds(
      updateDoc(doc(admin, "users", "user2"), {
        account_status: "active",
      })
    );
    console.log("PASS 19: Admin can reactivate user");

    // TEST 20
    await assertFails(
      setDoc(
        doc(user, "post_reports", "report7"),
        {
          ...createReport("user1"),
          reportedUserId: "admin2",
        }
      )
    );
    console.log("PASS 20: Incorrect reported user blocked");

    console.log("\nALL 20 REPORT SECURITY TESTS PASSED!");

  } finally {
    await env.cleanup();
  }
}

runTests().catch((error) => {
  console.error("TEST FAILED:", error);
  process.exitCode = 1;
});
