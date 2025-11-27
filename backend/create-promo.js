#!/usr/bin/env node

/**
 * Admin Script to Create Promo Codes
 * Run: node create-promo.js
 */

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function createPromoCodes() {
    console.log('🎉 Creating exclusive promo codes...\n');

    const promoCodes = [
        {
            code: 'BODAIApropirty',
            discountValue: 90,
            description: '🔥 90% OFF - Ultra Secret Code'
        },
        {
            code: 'BODAIAsubject',
            discountValue: 50,
            description: '💎 50% OFF - VIP Code'
        },
        {
            code: 'NOTWORTHYGIFT',
            discountValue: 10,
            description: '🎁 10% OFF - Gift Code'
        },
        {
            code: 'PCPOSLAUNCH',
            discountValue: 20,
            description: '🚀 20% OFF - Launch Code'
        }
    ];

    try {
        for (const promo of promoCodes) {
            try {
                const created = await prisma.promoCode.create({
                    data: {
                        code: promo.code,
                        type: 'PERCENTAGE',
                        discountValue: promo.discountValue,
                        active: true,
                        maxUses: null, // Unlimited uses
                        expiresAt: null // Never expires (first month only applies via StoreKit)
                    }
                });

                console.log(`✅ ${promo.description}`);
                console.log(`   Code: ${created.code}`);
                console.log(`   Discount: ${created.discountValue}%`);
                console.log('');

            } catch (error) {
                if (error.code === 'P2002') {
                    console.log(`⚠️  "${promo.code}" already exists`);
                    const existing = await prisma.promoCode.findUnique({
                        where: { code: promo.code }
                    });
                    if (existing) {
                        console.log(`   Active: ${existing.active}, Uses: ${existing.usesCount}`);
                    }
                    console.log('');
                } else {
                    throw error;
                }
            }
        }

        console.log('🎯 All promo codes ready!');
        console.log('\n📋 Summary:');
        console.log('   BODAIApropirty → 90% off (SECRET!)');
        console.log('   BODAIAsubject → 50% off (VIP)');
        console.log('   NOTWORTHYGIFT → 10% off (Gift)');
        console.log('   PCPOSLAUNCH → 20% off (Public)');

    } catch (error) {
        console.error('❌ Error creating promo codes:', error);
    } finally {
        await prisma.$disconnect();
    }
}

createPromoCodes();
