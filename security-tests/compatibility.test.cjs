const fs = require("node:fs");
const assert = require("node:assert/strict");

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails
} = require("@firebase/rules-unit-testing");

const {
  doc,
  setDoc,
  getDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp
} = require("firebase/firestore");

async function main() {
  const env = await initializeTestEnvironment({
    projectId: "demo-pawly-test",
    firestore: {
      host: "127.0.0.1",
      port: 8081,
      rules: fs.readFileSync("../firestore.rules", "utf8")
    }
  });

  let passed = 0;

  async function check(name, action) {
    await action();
    passed++;
    console.log("PASS " + passed + ": " + name);
  }

  try {
    await env.clearFirestore();

    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      for (const [uid, role, status] of [
        ["donor", "user", "active"],
        ["other", "user", "active"],
        ["admin", "admin", "active"],
        ["banned", "user", "banned"]
      ]) {
        await setDoc(doc(db, "users", uid), {
          uid,
          role,
          account_status: status
        });
      }

      await setDoc(doc(db, "posts", "pet1"), {
        userId: "other",
        animalName: "Test Dog"
      });
    });

    const user = env.authenticatedContext("donor").firestore();
    const other = env.authenticatedContext("other").firestore();
    const admin = env.authenticatedContext("admin").firestore();
    const banned = env.authenticatedContext("banned").firestore();

    const donation = {
      amount: 500,
      currency: "LKR",
      status: "pending",
      created_at: serverTimestamp()
    };

    await check("Valid donation allowed", () =>
      assertSucceeds(setDoc(doc(user, "users/donor/donations/d1"), donation)));

    await check("Invalid amount blocked", () =>
      assertFails(setDoc(doc(user, "users/donor/donations/d2"), {
        ...donation, amount: -500
      })));

    await check("Excessive amount blocked", () =>
      assertFails(setDoc(doc(user, "users/donor/donations/d3"), {
        ...donation, amount: 1000001
      })));

    await check("Fake payment confirmation blocked", () =>
      assertFails(updateDoc(doc(user, "users/donor/donations/d1"), {
        status: "paid"
      })));

    await check("Other user donation protected", () =>
      assertFails(getDoc(doc(other, "users/donor/donations/d1"))));

    await check("Admin can review donation", () =>
      assertSucceeds(getDoc(doc(admin, "users/donor/donations/d1"))));

    await check("Banned user donation blocked", () =>
      assertFails(setDoc(doc(banned, "users/banned/donations/d1"), donation)));

    const care = {
      postId: "pet1",
      animalName: "Test Dog",
      reporterId: "other",
      caregiverId: "donor",
      careTypes: ["Food", "Water"],
      description: "Provided food and water.",
      evidenceImageUrl: "https://res.cloudinary.com/mdpqtvkq/image/upload/test.jpg",
      status: "Submitted",
      createdAt: serverTimestamp()
    };

    await check("Valid tender care record allowed", () =>
      assertSucceeds(setDoc(doc(user, "tender_records/t1"), care)));

    await check("Invalid care type blocked", () =>
      assertFails(setDoc(doc(user, "tender_records/t2"), {
        ...care, careTypes: ["Invalid"]
      })));

    await check("Invalid image URL blocked", () =>
      assertFails(setDoc(doc(user, "tender_records/t3"), {
        ...care, evidenceImageUrl: "https://example.com/test.jpg"
      })));

    await check("Fake caregiver blocked", () =>
      assertFails(setDoc(doc(user, "tender_records/t4"), {
        ...care, caregiverId: "other"
      })));

    await check("Other user care record protected", () =>
      assertFails(getDoc(doc(other, "tender_records/t1"))));

    await check("Admin can review care record", () =>
      assertSucceeds(getDoc(doc(admin, "tender_records/t1"))));

    await check("Submitted evidence modification blocked", () =>
      assertFails(updateDoc(doc(user, "tender_records/t1"), {
        description: "Changed evidence"
      })));

    await check("Submitted evidence deletion blocked", () =>
      assertFails(deleteDoc(doc(user, "tender_records/t1"))));

    assert.equal(passed, 15);
    console.log("ALL 15 ADDITIONAL SECURITY TESTS PASSED!");

  } finally {
    await env.cleanup();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
