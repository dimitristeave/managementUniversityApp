const admin = require("firebase-admin");

const serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  //databaseURL: "https://isibappsmoodle.firebaseio.com"
});

const db = admin.firestore();
console.log(db);
async function testFirestore() {
  try {
    const docRef = await db.collection("matieres").add({
      name: "Test Server",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log("Document ajouté avec succès avec ID :", docRef.id);
  } catch (error) {
    console.error("Erreur lors de l'ajout :", error);
  }
}

testFirestore();