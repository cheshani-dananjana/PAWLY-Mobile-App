
const fs = require("node:fs");
const path = require("node:path");

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");

const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
} = require("firebase/firestore");

async function runTests() {
  const env = await initializeTestEnvironment({
    projectId: "demo-pawly",
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: fs.readFileSync(
        path.join(__dirname, "../firestore.rules"),
        "utf8"
      ),
    },
  });

  try {
    // Clear local emulator test data
    await env.clearFirestore();

    // Create sample test users
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      const users = [
        ["user1", "user", "active"],
        ["user2", "user", "active"],
        ["admin1", "admin", "active"],
        ["banned1", "user", "banned"],
        ["disabled1", "user", "disabled"],
      ];

      for (const [uid, role, status] of users) {
        await setDoc(doc(db, "users", uid), {
          uid: uid,
          full_name: uid,
          role: role,
          account_status: status,
          email: `${uid}@example.com`,
          phone_number: "0770000000",
        });
      }

      // Create sample animal post
      await setDoc(doc(db, "posts", "post1"), {
        name: "Test Animal",
        userId: "user1",
      });

      // Create sample adoption application
      await setDoc(
        doc(db, "adoption_applications", "app1"),
        {
          applicantId: "user2",
          status: "Pending",
        }
      );
    });

    // Create authenticated test environments
    const user = env
      .authenticatedContext("user1")
      .firestore();

    const admin = env
      .authenticatedContext("admin1")
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

    // Test 01: Read own profile
    await assertSucceeds(
      getDoc(doc(user, "users", "user1"))
    );

    console.log("PASS 01: Read own profile");

    // Test 02: Protect other user profiles
    await assertFails(
      getDoc(doc(user, "users", "user2"))
    );

    console.log("PASS 02: Other user profile blocked");

    // Test 03: Prevent unauthorized role changes
    await assertFails(
      updateDoc(doc(user, "users", "user1"), {
        role: "admin",
      })
    );

    console.log(
      "PASS 03: Unauthorized role change blocked"
    );

    // Test 04: Prevent own account status changes
    await assertFails(
      updateDoc(doc(user, "users", "user1"), {
        account_status: "banned",
      })
    );

    console.log(
      "PASS 04: Own account status change blocked"
    );

    // Test 05: Allow profile editing
    await assertSucceeds(
      updateDoc(doc(user, "users", "user1"), {
        full_name: "Updated Name",
      })
    );

    console.log("PASS 05: Edit own profile");

    // Test 06: Block banned users
    await assertFails(
      getDoc(doc(banned, "posts", "post1"))
    );

    console.log("PASS 06: Banned user access blocked");

    // Test 07: Block disabled users
    await assertFails(
      getDoc(doc(disabled, "posts", "post1"))
    );

    console.log("PASS 07: Disabled user access blocked");

    // Test 08: Protect private adoption applications
    await assertFails(
      getDoc(
        doc(user, "adoption_applications", "app1")
      )
    );

    console.log(
      "PASS 08: Private application protected"
    );

    // Test 09: Allow admin to ban users
    await assertSucceeds(
      updateDoc(doc(admin, "users", "user2"), {
        account_status: "banned",
      })
    );

    console.log("PASS 09: Admin can ban user");

    // Test 10: Allow admin to reactivate users
    await assertSucceeds(
      updateDoc(doc(admin, "users", "user2"), {
        account_status: "active",
      })
    );

    console.log("PASS 10: Admin can reactivate user");

    // Test 11: Block unauthenticated users
    await assertFails(
      getDoc(doc(guest, "posts", "post1"))
    );

    console.log(
      "PASS 11: Unauthenticated access blocked"
    );

    console.log(
      "\nALL 11 SECURITY TESTS PASSED!"
    );

  } finally {
    await env.cleanup();
  }
}

runTests().catch((error) => {
  console.error("TEST FAILED:", error);
  process.exitCode = 1;
});
