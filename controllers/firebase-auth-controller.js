const admin = require("firebase-admin");
const db = admin.firestore();

class FirebaseAuthController {

    signup = async (req, res) => {
        const { email, password, section} = req.body;
    
        if (!email || !password || !section) {
            return res.status(400).send({ error: "Email et mot de passe ou section sont requis." });
        }
    
        // Vérification de la longueur minimale du mot de passe (6 caractères)
        if (password.length < 6) {
            return res.status(400).send({ error: "Le mot de passe doit comporter au moins 6 caractères." });
        }
    
        try {
            // Vérifier si l'email existe déjà
            try {
                await admin.auth().getUserByEmail(email);
                return res.status(400).send({ error: "Cet email est déjà utilisé." });
            } catch (error) {
                if (error.code !== 'auth/user-not-found') {
                    // Si une erreur autre que 'user-not-found' se produit
                    console.error("Erreur lors de la vérification de l'email :", error);
                    return res.status(500).send({ error: "Erreur interne du serveur." });
                }
            }
    
            // Si l'email n'est pas trouvé, procéder à la création de l'utilisateur
            const userRecord = await admin.auth().createUser({
                email: email,
                password: password,
            });
    
            const user = userRecord;  // userRecord contient l'objet utilisateur créé
    
            // Vérifier que l'objet user est valide
            if (!user || !user.uid) {
                return res.status(500).send({ error: "Erreur lors de la création de l'utilisateur." });
            }
    
            // Déterminer le rôle en fonction de l'email
            let role = '';
            if (email.endsWith('@etu.he2b.be')) {
                role = 'student';  // Etudiant
            } else if (email.endsWith('@he2b.be')) {
                role = 'professor'; // Professeur
            } else {
                return res.status(403).send({ error: 'Email non autorisé' });
            }
    
            // Enregistrer l'utilisateur dans Firestore avec son rôle
            await db.collection('users').doc(user.uid).set({
                email: email,
                role: role,
                section : section,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
    
            // Créer un token personnalisé pour cet utilisateur
            const idToken = await admin.auth().createCustomToken(user.uid, { role });
    
            // Retourner le token et le rôle de l'utilisateur
            res.status(201).send({ idToken, role });
    
        } catch (error) {
            console.error("Erreur lors de l'inscription :", error);
            res.status(500).send({ error: "Erreur interne du serveur." });
        }
    }
}

module.exports = new FirebaseAuthController();
