import express, { Router, Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const router: Router = express.Router();
const prisma = new PrismaClient();

// Generate unique referral code
function generateReferralCode(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = 'PCPOS-';
    for (let i = 0; i < 6; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
}

// POST /api/referrals/generate - Generate referral code for user
router.post('/generate', async (req: Request, res: Response) => {
    try {
        const { userId } = req.body;

        if (!userId) {
            return res.status(400).json({ error: 'userId is required' });
        }

        // Check if user already has a referral code
        let referralCode = await prisma.referralCode.findUnique({
            where: { userId }
        });

        if (!referralCode) {
            // Generate new code
            let code = generateReferralCode();
            let attempts = 0;

            // Ensure code is unique
            while (attempts < 5) {
                const existing = await prisma.referralCode.findUnique({
                    where: { code }
                });

                if (!existing) break;
                code = generateReferralCode();
                attempts++;
            }

            referralCode = await prisma.referralCode.create({
                data: {
                    userId,
                    code
                }
            });
        }

        res.json({
            code: referralCode.code,
            shareUrl: `https://pcposcompanion.app/ref/${referralCode.code}`
        });
    } catch (error) {
        console.error('Error generating referral code:', error);
        res.status(500).json({ error: 'Failed to generate referral code' });
    }
});

// POST /api/referrals/validate - Validate referral or promo code
router.post('/validate', async (req: Request, res: Response) => {
    try {
        const { code, userId } = req.body;

        if (!code) {
            return res.status(400).json({ error: 'code is required' });
        }

        // Check if it's a referral code
        const referralCode = await prisma.referralCode.findUnique({
            where: { code }
        });

        if (referralCode) {
            // Check if user is trying to use their own code
            if (userId && referralCode.userId === userId) {
                return res.json({
                    valid: false,
                    error: 'Cannot use your own referral code'
                });
            }

            // Check if user already used a referral code
            if (userId) {
                const existingReferral = await prisma.referral.findUnique({
                    where: { refereeId: userId }
                });

                if (existingReferral) {
                    return res.json({
                        valid: false,
                        error: 'You have already used a referral code'
                    });
                }
            }

            return res.json({
                valid: true,
                type: 'REFERRAL',
                discount: {
                    type: 'PERCENTAGE',
                    value: 10,
                    duration: 'first_month'
                }
            });
        }

        // Check if it's a promo code
        const promoCode = await prisma.promoCode.findUnique({
            where: { code }
        });

        if (promoCode) {
            // Check if promo code is active
            if (!promoCode.active) {
                return res.json({
                    valid: false,
                    error: 'This promo code is no longer active'
                });
            }

            // Check expiration
            if (promoCode.expiresAt && new Date() > promoCode.expiresAt) {
                return res.json({
                    valid: false,
                    error: 'This promo code has expired'
                });
            }

            // Check max uses
            if (promoCode.maxUses && promoCode.usesCount >= promoCode.maxUses) {
                return res.json({
                    valid: false,
                    error: 'This promo code has reached its usage limit'
                });
            }

            // Check if user already used this promo
            if (userId) {
                const existingRedemption = await prisma.promoRedemption.findFirst({
                    where: {
                        userId,
                        promoCodeId: promoCode.id
                    }
                });

                if (existingRedemption) {
                    return res.json({
                        valid: false,
                        error: 'You have already used this promo code'
                    });
                }
            }

            return res.json({
                valid: true,
                type: 'PROMO',
                discount: {
                    type: promoCode.type,
                    value: promoCode.discountValue,
                    duration: 'first_month'
                }
            });
        }

        res.json({
            valid: false,
            error: 'Invalid code'
        });
    } catch (error) {
        console.error('Error validating code:', error);
        res.status(500).json({ error: 'Failed to validate code' });
    }
});

// POST /api/referrals/apply - Apply referral code when user subscribes
router.post('/apply', async (req: Request, res: Response) => {
    try {
        const { referralCode, refereeId } = req.body;

        if (!referralCode || !refereeId) {
            return res.status(400).json({ error: 'referralCode and refereeId are required' });
        }

        // Find the referral code
        const code = await prisma.referralCode.findUnique({
            where: { code: referralCode }
        });

        if (!code) {
            return res.status(404).json({ error: 'Invalid referral code' });
        }

        // Check if user already used a referral
        const existingReferral = await prisma.referral.findUnique({
            where: { refereeId }
        });

        if (existingReferral) {
            return res.status(400).json({ error: 'User has already used a referral code' });
        }

        // Create referral record
        const referral = await prisma.referral.create({
            data: {
                referrerId: code.userId,
                refereeId,
                codeUsed: referralCode,
                discountApplied: true,
                active: true
            }
        });

        // Update referral code uses
        await prisma.referralCode.update({
            where: { code: referralCode },
            data: {
                usesCount: { increment: 1 }
            }
        });

        // Mark referrer as having discount
        await prisma.user.update({
            where: { id: code.userId },
            data: {
                hasReferralDiscount: true
            }
        });

        res.json({
            success: true,
            referrerId: code.userId,
            discountApplied: true
        });
    } catch (error) {
        console.error('Error applying referral:', error);
        res.status(500).json({ error: 'Failed to apply referral code' });
    }
});

// POST /api/referrals/redeem-promo - Redeem promo code
router.post('/redeem-promo', async (req: Request, res: Response) => {
    try {
        const { code, userId } = req.body;

        if (!code || !userId) {
            return res.status(400).json({ error: 'code and userId are required' });
        }

        const promoCode = await prisma.promoCode.findUnique({
            where: { code }
        });

        if (!promoCode || !promoCode.active) {
            return res.status(404).json({ error: 'Invalid promo code' });
        }

        // Check if already redeemed
        const existing = await prisma.promoRedemption.findFirst({
            where: {
                userId,
                promoCodeId: promoCode.id
            }
        });

        if (existing) {
            return res.status(400).json({ error: 'Promo code already redeemed' });
        }

        // Create redemption
        await prisma.promoRedemption.create({
            data: {
                userId,
                promoCodeId: promoCode.id,
                codeUsed: code
            }
        });

        // Update promo code uses
        await prisma.promoCode.update({
            where: { id: promoCode.id },
            data: {
                usesCount: { increment: 1 }
            }
        });

        res.json({
            success: true,
            discount: {
                type: promoCode.type,
                value: promoCode.discountValue
            }
        });
    } catch (error) {
        console.error('Error redeeming promo:', error);
        res.status(500).json({ error: 'Failed to redeem promo code' });
    }
});

// GET /api/referrals/stats/:userId - Get user's referral statistics
router.get('/stats/:userId', async (req: Request, res: Response) => {
    try {
        const { userId } = req.params;

        const referralCode = await prisma.referralCode.findUnique({
            where: { userId },
            include: {
                referrals: {
                    where: { active: true }
                }
            }
        });

        if (!referralCode) {
            return res.json({
                code: null,
                totalReferrals: 0,
                currentDiscount: 0,
                savings: 0
            });
        }

        const activeReferrals = referralCode.referrals.length;
        const monthlyDiscount = activeReferrals * 7.99;

        res.json({
            code: referralCode.code,
            totalReferrals: referralCode.usesCount,
            activeReferrals,
            currentDiscount: monthlyDiscount,
            savings: monthlyDiscount // Could calculate total savings over time
        });
    } catch (error) {
        console.error('Error fetching stats:', error);
        res.status(500).json({ error: 'Failed to fetch referral stats' });
    }
});

// POST /api/referrals/deactivate - Deactivate a referral (when referee unsubscribes)
router.post('/deactivate', async (req: Request, res: Response) => {
    try {
        const { refereeId } = req.body;

        if (!refereeId) {
            return res.status(400).json({ error: 'refereeId is required' });
        }

        await prisma.referral.update({
            where: { refereeId },
            data: { active: false }
        });

        res.json({ success: true });
    } catch (error) {
        console.error('Error deactivating referral:', error);
        res.status(500).json({ error: 'Failed to deactivate referral' });
    }
});

export default router;
