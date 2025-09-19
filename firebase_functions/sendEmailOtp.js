const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Initialize Firebase Admin
admin.initializeApp();

// Configure Gmail transporter
const transporter = nodemailer.createTransporter({
  service: 'gmail',
  auth: {
    user: functions.config().gmail?.email || 'your-email@gmail.com',
    pass: functions.config().gmail?.password || 'your-app-password',
  },
});

exports.sendEmailOtp = functions.https.onCall(async (data, context) => {
  try {
    const { email, otp, userRole } = data;

    // Validate input
    if (!email || !otp || !userRole) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required parameters: email, otp, userRole'
      );
    }

    // Email template
    const mailOptions = {
      from: `Civic Lense <${functions.config().gmail?.email || 'your-email@gmail.com'}>`,
      to: email,
      subject: `Your Civic Lense OTP for ${userRole} Verification`,
      html: `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Civic Lense OTP</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: #007bff; color: white; padding: 20px; text-align: center; }
                .content { padding: 20px; background: #f9f9f9; }
                .otp-code { font-size: 32px; font-weight: bold; color: #007bff; text-align: center; margin: 20px 0; padding: 20px; background: white; border-radius: 8px; }
                .footer { padding: 20px; text-align: center; color: #666; font-size: 14px; }
                .warning { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 15px 0; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🔐 Civic Lense OTP Verification</h1>
                </div>
                <div class="content">
                    <h2>Dear ${userRole} User,</h2>
                    <p>Your One-Time Password (OTP) for Civic Lense verification is:</p>
                    
                    <div class="otp-code">${otp}</div>
                    
                    <div class="warning">
                        <strong>⚠️ Important Security Information:</strong>
                        <ul>
                            <li>This OTP is valid for <strong>10 minutes</strong></li>
                            <li>Do not share this code with anyone</li>
                            <li>If you didn't request this verification, please ignore this email</li>
                        </ul>
                    </div>
                    
                    <p>Thank you for using Civic Lense!</p>
                </div>
                <div class="footer">
                    <p>This is an automated message from Civic Lense.<br>
                    Please do not reply to this email.</p>
                </div>
            </div>
        </body>
        </html>
      `,
    };

    // Send email
    await transporter.sendMail(mailOptions);
    
    console.log(`OTP email sent successfully to ${email}`);
    
    return { 
      success: true, 
      message: 'OTP email sent successfully!' 
    };

  } catch (error) {
    console.error('Error sending OTP email:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send OTP email',
      error.message
    );
  }
});
