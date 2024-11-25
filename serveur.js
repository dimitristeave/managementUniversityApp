const express = require("express");
const bodyParser = require("body-parser");
const admin = require("firebase-admin");
const multer = require("multer");
const path = require("path");

// Initialisation de Firebase Admin SDK
const serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const app = express();
app.use(bodyParser.json());

// Route POST pour ajouter une matière
app.post("/addSubject", async (req, res) => {
  const { classe, filiere, id_matiere, nom_matiere, nom_prof } = req.body;
  if (!classe || !filiere || !nom_matiere || !id_matiere || !nom_prof) {
    return res.status(400).send({ error: "Tous les champs sont obligatoires." });
  }

  try {
    // Enregistrement dans Firestore
    const docRef = await db.collection("matieres").add({
      classe: classe,
      filiere,
      id_matiere,
      nom_matiere,
      nom_prof,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(200).send({ message: "Matière ajoutée avec succès.", id: docRef.id });
  } catch (error) {
    console.error("Erreur lors de l'ajout :", error);
    res.status(500).send({ error: "Erreur interne du serveur." });
  }
});

// Route GET pour récupérer les matières par classe
app.get("/getSubjectsByClass", async (req, res) => {
  const classe = req.query.classe;
  var filiere = req.query.filiere;

  if (classe != "Master 1" && classe != "Master 2") {
    filiere = "Commun";
  }

  console.log(filiere);
  if (!classe) {
    return res.status(400).send({ error: "Classe manquante dans la requête." });
  }

  try {
    const snapshot = await db
      .collection("matieres")
      .where("classe", "==", classe) .where("filiere", "==", filiere)
      .get();

    if (snapshot.empty) {
      return res.status(200).send([]);
    }

    const subjects = snapshot.docs.map((doc) => doc.data());
    res.status(200).send(subjects);
  } catch (error) {
    console.error("Erreur lors de la récupération des matières :", error);
    res.status(500).send({ error: "Erreur interne du serveur." });
  }
});

// Route GET pour obtenir les notes par matière
app.get("/getNotes", async (req, res) => {
  const subjectName = req.query.subjectName;

  // Vérification du paramètre obligatoire
  if (!subjectName) {
    return res
      .status(400)
      .send({ error: "Le paramètre 'subjectName' est obligatoire." });
  }

  try {
    // Requête pour récupérer les notes correspondant à la matière
    const snapshot = await db
      .collection("notes")
      .where("subjectName", "==", subjectName)
      .orderBy("createdAt", "desc")
      .get();

    if (snapshot.empty) {
      return res.status(200).send([]); // Retourne une liste vide si aucune note n'est trouvée
    }

    // Extraction des données des documents
    const notes = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    res.status(200).send(notes);
  } catch (error) {
    console.error("Erreur lors de la récupération des notes :", error);
    res
      .status(500)
      .send({ error: "Erreur interne lors de la récupération des notes." });
  }
});



// Configuration du stockage multer (enregistrement dans un dossier local)
// Configuration de Multer pour le stockage des fichiers
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, "uploads")); // Répertoire où les fichiers seront sauvegardés
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, uniqueSuffix + path.extname(file.originalname)); // Nom unique pour éviter les conflits
  },
});

const upload = multer({ storage: storage });

// Route POST pour uploader une note
app.post("/uploadNote", upload.single("file"), async (req, res) => {
  const { subjectName, fileName, noteDescription, contentType, noteDate } = req.body;

  // Vérification des champs obligatoires
  if (!req.file || !subjectName || !fileName || !noteDescription || !contentType || !noteDate) {
    return res.status(400).send({ error: "Tous les champs sont obligatoires, fichier inclus." });
  }

  try {
    // Ajout des métadonnées dans Firestore
    const docRef = await db.collection("notes").add({
      subjectName,
      fileName,
      noteDescription,
      contentType,
      noteDate,
      filePath: req.file.path, // Chemin local du fichier
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(200).send({
      message: "Note uploadée avec succès.",
      id: docRef.id,
      filePath: req.file.path,
    });
  } catch (error) {
    console.error("Erreur lors de l'upload :", error);
    res.status(500).send({ error: "Erreur interne du serveur." });
  }
});


// Lancer le serveur
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Serveur en cours d'exécution sur le port ${PORT}`);
});
