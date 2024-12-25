const admin = require("firebase-admin");
const db = admin.firestore();

class OpportunityController {

    addWork = async (req, res) => {
        const { company, section, address, description, link } = req.body;
    
        if (!company || !section || !address|| !description || !link) {
            return res.status(400).send({ error: "Des informations sont manquantes, verifiez que tout vos champs sont complets." });
        }
        
        try {

            // Enregistrer l'offre d'emploi dans Firestore
            const docRef = await db.collection('works').add({
                company: company,
                section: section,
                address : address,
                description : description,
                link : link,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            // Retourner le token et le rôle de l'utilisateur
            res.status(201).send({ documentId : docRef.id, message : "L'offre a été ajoutée avec succès." });
    
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
                return res.status(404).send({ message: "Aucune opportunité trouvée." });
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
}

module.exports = new OpportunityController();
