const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { utils } = require('near-api-js');
const { PublicKey, KeyPair } = utils.key_pair;
const bs58 = require('bs58');

admin.initializeApp();
const db = admin.firestore();

exports.verifySignedTransaction = functions.https.onCall(async (body, context) => {
    const { signedTx, publicKeyStr, uuid, accountId } = body.data;
    console.log('body.data:', body.data);
    console.log('Received signedTx:', signedTx);
    console.log('Received publicKeyStr:', publicKeyStr);
    console.log('Received uuid:', uuid);
    console.log('Received accountId:', accountId);

    try {
        const publicKeyBase58 = bs58.default.encode(Buffer.from(publicKeyStr, 'hex'));

        console.log('Converted publicKey to base58:', publicKeyBase58);

        const publicKey = PublicKey.fromString(publicKeyBase58);

        console.log('Parsed PublicKey:', publicKey.toString());

        const isValidSignature = verifyTransactionSignature(signedTx, publicKey);

        console.log('Signature is valid:', isValidSignature);

        // if (!isValidSignature) {
        //     console.error('Invalid signature for transaction');
        //     throw new functions.https.HttpsError('invalid-argument', 'Invalid signature');
        // }

        await db.collection('sessions').doc(uuid).set({
            accountId: accountId,
            isActive: true,
        });

        console.log(`Session created for uuid: ${uuid}, accountId: ${accountId}`);

        return { success: true };

    } catch (error) {
        console.error('Error verifying transaction:', error);
        throw new functions.https.HttpsError('internal', 'Verification failed');
    }
});

function extractTxAndSignature(signedTx) {
    const decodedTx = Buffer.from(signedTx, 'base64');

    const signatureLength = 64;

    const txData = decodedTx.slice(0, decodedTx.length - signatureLength - 1);
    const signature = decodedTx.slice(decodedTx.length - signatureLength);

    return { txData, signature };
}


function verifyTransactionSignature(signedTx, publicKey) {
    try {
        const { txData, signature } = extractTxAndSignature(signedTx);

        console.log('txData :: ', txData);
        console.log('signature :: ', signature);


        const isValid = publicKey.verify(txData, signature);

        console.log('Verification result:', isValid);
        return isValid;
    } catch (error) {
        console.error('Error during signature verification:', error);
        return false;
    }
}