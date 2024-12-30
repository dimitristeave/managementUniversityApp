const express = require("express");
const bodyParser = require("body-parser");
const admin = require("firebase-admin");
const multer = require("multer");
const path = require("path");
const fs = require('fs');
const nodemailer = require('nodemailer');

// Initialisation de Firebase Admin SDK
const serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const app = express();

// Configuration du transporteur de mail
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'kenmotagn@gmail.com', // Remplacez par votre email
    pass: 'drtc ucna smnz ggxg' // Utilisez un mot de passe d'application Gmail
  }
});

//Middleware
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
    console.log(subjects);
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

// Route GET pour télécharger une note
app.get("/downloadNote/:id", async (req, res) => {
  try {
    console.log("Download request for ID:", req.params.id); // Log pour debug

    const noteDoc = await db.collection("notes").doc(req.params.id).get();
    if (!noteDoc.exists) {
      console.log("Note not found in Firestore"); // Log pour debug
      return res.status(404).send({ error: "Note non trouvée." });
    }

    const noteData = noteDoc.data();
    console.log("Note data:", noteData); // Log pour debug

    const filePath = noteData.filePath;
    console.log("File path:", filePath); // Log pour debug

    if (!fs.existsSync(filePath)) {
      console.log("File does not exist at path:", filePath); // Log pour debug
      return res.status(404).send({ error: "Fichier non trouvé." });
    }

    res.download(filePath, noteData.fileName);
  } catch (error) {
    console.error("Download error:", error); // Log détaillé de l'erreur
    res.status(500).send({ error: "Erreur interne du serveur." });
  }
});

// Route POST pour créer une demande d'assistance
app.post("/assistance", async (req, res) => {
  const {
    matiere,
    destinataireId,
    destinataireEmail,
    date,
    heures,
    lieu,
    description,
    demandeurId,
    demandeurEmail,
    demandeurClasse,
    demandeurFiliere,
    status // 'en attente', 'accepté', 'refusé'
  } = req.body;

  try {
    const docRef = await db.collection("assistance").add({
      matiere,
      destinataireId,
      destinataireEmail,
      date,
      heures,
      lieu,
      description,
      demandeurId,
      demandeurEmail,
      demandeurClasse,
      demandeurFiliere,
      status: 'en attente',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(200).send({
      message: "Demande envoyée avec succès.",
      id: docRef.id
    });
  } catch (error) {
    console.error("Erreur:", error);
    res.status(500).send({ error: "Erreur interne du serveur." });
  }
});

// Route pour récupérer la liste des utilisateurs
// Dans la route GET /assistance/:userId
app.get("/assistance/:userId", async (req, res) => {
  const userId = req.params.userId;

  try {
    // Récupérer les demandes
    const snapshot = await db.collection("assistance")
      .where("destinataireId", "==", userId)
      .orderBy("createdAt", "desc")
      .get();
    //console.log("0");
    // Récupérer les demandes avec les infos des demandeurs
    const demandes = await Promise.all(snapshot.docs.map(async doc => {
      const demandeData = doc.data();
      // Récupérer les infos du demandeur
      const userDoc = await db.collection("users").doc(demandeData.demandeurId).get();
      const userData = userDoc.data();

      return {
        id: doc.id,
        ...demandeData,
        demandeurClasse: userData?.classe || 'Non spécifié',
        demandeurFiliere: userData?.filiere || 'Non spécifié',
      };
    }));
    //console.log(demandes);
    res.status(200).send(demandes);
  } catch (error) {
    console.log("0");
    console.error("Erreur:", error);
    res.status(500).send({ error: "Erreur interne du serveur." });
  }
});

app.get("/user/:id", async (req, res) => {
  try {
    const userDoc = await db.collection("users").doc(req.params.id).get();
    if (!userDoc.exists) {
      return res.status(404).send({ error: "Utilisateur non trouvé" });
    }

    const userData = userDoc.data();
    console.log(userData);
    res.status(200).send({
      email: userData.email,
      classe: userData.classe,
      filiere: userData.filiere
    });
  } catch (error) {
    console.error("Erreur:", error);
    res.status(500).send({ error: "Erreur interne du serveur" });
  }
});

app.get("/users", async (req, res) => {
  try {
    const usersSnapshot = await db.collection("users").get();

    // Initialiser les tableaux pour les deux types d'utilisateurs
    const professors = [];
    const students = [];

    // Parcourir tous les utilisateurs et les séparer selon leur rôle
    usersSnapshot.forEach(doc => {
      const userData = {
        uid: doc.id,
        email: doc.data().email,
        classe: doc.data().classe,
        filiere: doc.data().filiere
      };

      if (doc.data().role === 'professor') {
        professors.push(userData);
      } else {
        students.push(userData);
      }
    });

    // Envoyer les deux tableaux dans la réponse
    res.status(200).send({
      professors,
      students
    });

  } catch (error) {
    console.error("Erreur lors de la récupération des utilisateurs:", error);
    res.status(500).send({ error: "Erreur interne du serveur" });
  }
});

// Récupérer mes demandes envoyées
app.get("/assistance/mes-demandes/:userId", async (req, res) => {
  const userId = req.params.userId;

  try {
    const snapshot = await db.collection("assistance")
      .where("demandeurId", "==", userId)
      .orderBy("createdAt", "desc")
      .get();

    const demandes = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.status(200).send(demandes);
  } catch (error) {
    console.error("Erreur:", error);
    res.status(500).send({ error: "Erreur interne du serveur." });
  }
});

// Mettre à jour le statut d'une demande
app.put("/assistance/update/:id", async (req, res) => {
  try {
    const demandeId = req.params.id;
    const { status } = req.body;
    console.log(demandeId);
    if (!['accepté', 'refusé'].includes(status)) {
      return res.status(400).send({ error: "Statut invalide" });
    }

    await db.collection("assistance").doc(demandeId).update({
      status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Si la demande est acceptée, envoyer un email
    if (status === 'accepté') {
      // Récupérer les détails de la demande
      const demandeDoc = await db.collection("assistance").doc(demandeId).get();
      const demandeData = demandeDoc.data();

      // Récupérer les détails du demandeur
      const demandeurDoc = await db.collection("users").doc(demandeData.demandeurId).get();
      const demandeurData = demandeurDoc.data();

      // Préparer le contenu de l'email
      const mailOptions = {
        from: 'kenmotagn@gmail.com',
        to: demandeData.destinataireEmail,
        subject: 'Demande d\'assistance acceptée',
        html: `
          <h2>Demande d'assistance acceptée</h2>
          <p>Vous avez accepté une demande d'assistance pour le cours de ${demandeData.matiere}.</p>
          
          <h3>Détails de la demande :</h3>
          <ul>
            <li><strong>Date :</strong> ${demandeData.date}</li>
            <li><strong>Durée :</strong> ${demandeData.heures} heures</li>
            <li><strong>Lieu :</strong> ${demandeData.lieu}</li>
          </ul>

          <h3>Coordonnées de l'étudiant :</h3>
          <ul>
            <li><strong>Nom :</strong> ${demandeurData.nom || 'Non spécifié'}</li>
            <li><strong>Email :</strong> ${demandeurData.email}</li>
            <li><strong>Classe :</strong> ${demandeurData.classe}</li>
            <li><strong>Filière :</strong> ${demandeurData.filiere}</li>
            ${demandeurData.telephone ? `<li><strong>Téléphone :</strong> ${demandeurData.telephone}</li>` : ''}
          </ul>

          <p><strong>Description de la demande :</strong><br>
          ${demandeData.description}</p>

          <p style="color: #666; font-size: 0.9em;">
            Cet email a été envoyé automatiquement par l'application ISIB Assistance.
          </p>
        `
      };

      // Envoyer l'email
      try {
        await transporter.sendMail(mailOptions);
        console.log('Email de confirmation envoyé');
      } catch (emailError) {
        console.error('Erreur lors de l\'envoi de l\'email:', emailError);
        // Ne pas bloquer la mise à jour si l'email échoue
      }
    }

    const updatedDoc = await db.collection("assistance").doc(demandeId).get();
    res.status(200).send({ id: updatedDoc.id, ...updatedDoc.data() });
  } catch (error) {
    console.error("Erreur:", error);
    res.status(500).send({ error: "Erreur lors de la mise à jour du statut." });
  }
});

// Supprimer une demande
app.delete("/assistance/:id", async (req, res) => {
  try {
    const demandeId = req.params.id;

    await db.collection("assistance").doc(demandeId).delete();
    res.status(200).send({ message: "Demande supprimée avec succès" });
  } catch (error) {
    console.error("Erreur:", error);
    res.status(500).send({ error: "Erreur lors de la suppression de la demande." });
  }
});



const firebaseAuthController = require('./controllers/firebase-auth-controller');
const opportunityController = require("./controllers/opportunity-controller")

// Route pour enregistrer l'utilisateur 
app.post('/signup', firebaseAuthController.signup);

//Route pour les opportunités de travail
app.post('/works', opportunityController.addWork);
app.get('/works', opportunityController.getWorks);
app.put('/works/:id', opportunityController.updateWorks);
app.delete('/works/:id', opportunityController.deleteWorks);

// Route pour ajouter ou mettre à jour les préférences
app.post('/preferences', opportunityController.updatePreferences);

// Route pour récupérer les préférences d'un utilisateur
app.get('/preferences/:userId', opportunityController.getPreferences);


// Lancer le serveur
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Serveur en cours d'exécution sur le port ${PORT}`);
});
