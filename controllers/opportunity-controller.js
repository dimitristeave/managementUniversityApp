const admin = require("firebase-admin");
const db = admin.firestore();

class OpportunityController {

    // Fonction pour nettoyer le nom de la section (remplacer les espaces par des underscores et supprimer les accents)
    cleanTopicName = (section) => {
        // Remplacer les espaces par des underscores
        let formattedSection = section.replace(/ /g, '_');
        
        // Supprimer les accents
        formattedSection = this.removeAccents(formattedSection);

        return formattedSection;
    }

    // Fonction pour supprimer les accents d'une chaîne
    removeAccents = (str) => {
        const accents = {
            'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
            'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a',
            'ç': 'c', 'è': 'e', 'î': 'i', 'ï': 'i',
            'ô': 'o', 'ö': 'o', 'ù': 'u', 'ü': 'u',
            'û': 'u', 'ÿ': 'y'
        };

        Object.keys(accents).forEach(accented => {
            str = str.replace(new RegExp(accented, 'g'), accents[accented]);
        });

        return str;
    }

    addWork = async (req, res) => {
        const { uid, company, type, section, address, description, link } = req.body;

        if (!uid || !company || !section || !address || !description || !type) {
            return res.status(400).send({ error: "Des informations sont manquantes, vérifiez que tout vos champs sont complets." });
        }        

        try {
            // Enregistrer l'offre d'emploi dans Firestore
            const docRef = await db.collection('works').add({
                uid: uid, // Ajouter l'UID de l'utilisateur
                company: company,
                type: type,
                section: section,
                address: address,
                description: description,
                link: link,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Nettoyer le nom de la section avant de l'utiliser comme topic
            const formattedSection = this.cleanTopicName(section);

            // Envoi d'une notification aux utilisateurs abonnés au topic de la section
            const message = {
                notification: {
                    title: 'Nouvelle opportunité!',
                    body: `Une nouvelle opportunité est disponible pour la section ${section}.`,
                },
                topic: formattedSection,  // Utilisation du nom nettoyé comme topic
            };

            await admin.messaging().send(message);

            // Retourner le token et le rôle de l'utilisateur
            res.status(201).send({ documentId: docRef.id, message: "L'offre a été ajoutée avec succès." });

        } catch (error) {
            console.error("Erreur lors de l'ajout de l'offre :", error);
            res.status(500).send({ error: "Erreur interne du serveur." });
        }
    }

    // Route pour récupérer toutes les opportunités
    getWorks = async (req, res) => {
        try {
            const snapshot = await db.collection('works').orderBy('createdAt', 'desc').get();
    
            // Vérifie si la collection est vide
            if (snapshot.empty) {
                return res.status(200).send([]);
            }
    
            // Transforme les documents en un tableau d'objets
            const works = snapshot.docs.map(doc => ({
                id: doc.id, // ID du document
                ...doc.data() // Données du document
            }));
            
            res.status(200).send(works);
        } catch (error) {
            console.error("Erreur lors de la récupération des opportunités :", error);
            res.status(500).send({ error: "Erreur interne du serveur." });
        }
    }

    updateWorks = async (req, res) => {
        const { id } = req.params;
        const updates = req.body;
        const userUid = req.headers['user-uid']; 
    
        try {
            const docRef = db.collection('works').doc(id);
            const doc = await docRef.get();
    
            // Vérifie si le document existe
            if (!doc.exists) {
                return res.status(404).send("Offre introuvable.");
            }
    
            // Vérifie si l'utilisateur est autorisé à modifier
            if (doc.data().uid !== userUid) {
                return res.status(403).send("Vous n'êtes pas autorisé à modifier cette opportunité.");
            }
    
            // Met à jour le document avec les nouvelles informations
            await docRef.update(updates);
    
            // Récupère le document mis à jour pour le renvoyer
            const updatedDoc = await docRef.get();
    
            res.status(200).json({ id: updatedDoc.id, ...updatedDoc.data() });
        } catch (error) {
            console.error("Erreur lors de la mise à jour de l'offre :", error);
            res.status(500).send("Erreur lors de la mise à jour.");
        }
    }
    
    deleteWorks = async (req, res) => {
        const { id} = req.params;
        const userUid = req.headers['user-uid']; 
    
        try {
            const docRef = db.collection('works').doc(id);
            const doc = await docRef.get();
    
            // Vérifie si le document existe
            if (!doc.exists) {
                return res.status(404).send("Offre introuvable.");
            }
    
            // Vérifie si l'utilisateur est autorisé à supprimer
            if (doc.data().uid !== userUid) {
                return res.status(403).send("Vous n'êtes pas autorisé à supprimer cette opportunité.");
            }
    
            // Supprime le document
            await docRef.delete();
    
            res.status(200).send("Offre supprimée avec succès.");
        } catch (error) {
            console.error("Erreur lors de la suppression de l'offre :", error);
            res.status(500).send("Erreur lors de la suppression.");
        }
    }

    

    // Ajouter ou mettre à jour les préférences de notification pour un utilisateur
    updatePreferences = async (req, res) => {
        const { userId, topics } = req.body;

        if (!userId || !Array.isArray(topics)) {
            return res.status(400).send({ error: "Les données sont invalides. Veuillez fournir un userId et une liste de topics." });
        }

        try {
            // Récupérer le document utilisateur
            const userDocRef = db.collection('users').doc(userId);
            const userDoc = await userDocRef.get();

            if (!userDoc.exists) {
                return res.status(404).send({ error: "Utilisateur introuvable." });
            }

            // Ajouter ou mettre à jour les préférences dans le document
            await userDocRef.update({ preferences: { topics } });

            res.status(200).send({ message: "Les préférences ont été mises à jour avec succès." });
        } catch (error) {
            console.error("Erreur lors de la mise à jour des préférences :", error);
            res.status(500).send({ error: "Erreur interne du serveur." });
        }
    };

    // Récupérer les préférences d'un utilisateur
    getPreferences = async (req, res) => {
        const { userId } = req.params;

        if (!userId) {
            return res.status(400).send({ error: "L'ID utilisateur est requis." });
        }

        try {
            // Récupérer les préférences depuis le document utilisateur
            const userDoc = await db.collection('users').doc(userId).get();

            if (!userDoc.exists) {
                return res.status(404).send({ error: "Utilisateur introuvable." });
            }

            const { preferences } = userDoc.data();

            // Retourner les préférences ou un tableau vide si elles n'existent pas
            res.status(200).send(preferences || { topics: [] });
        } catch (error) {
            console.error("Erreur lors de la récupération des préférences :", error);
            res.status(500).send({ error: "Erreur interne du serveur." });
        }
    };
    
}

module.exports = new OpportunityController();
