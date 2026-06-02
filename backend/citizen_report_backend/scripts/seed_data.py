"""
Demo seed data for development.
Run: python manage.py shell -c "from scripts.seed_data import seed; seed()"
"""
import random
from django.utils import timezone
from datetime import timedelta


def seed():
    from apps.users.models import User, UserRole
    from apps.complaints.models import (
        Complaint, ComplaintStatus, GovernmentLevel,
        ComplaintCategory, Comment, EscalationHistory
    )

    print("Seeding demo data...")

    # ─── Officers ─────────────────────────────────────────────────────────────
    officers = [
        dict(phone='+255700000001', full_name='Afisa Mtaa Kariakoo', role=UserRole.MTAA_OFFICER,
             mtaa='Kariakoo', ward='Kariakoo', district='Ilala', region='Dar es Salaam'),
        dict(phone='+255700000002', full_name='WEO Kariakoo', role=UserRole.WARD_OFFICER,
             ward='Kariakoo', district='Ilala', region='Dar es Salaam'),
        dict(phone='+255700000003', full_name='DC Ilala', role=UserRole.DISTRICT_OFFICER,
             district='Ilala', region='Dar es Salaam'),
        dict(phone='+255700000004', full_name='RC Dar es Salaam', role=UserRole.REGION_OFFICER,
             region='Dar es Salaam'),
        dict(phone='+255700000005', full_name='National Officer', role=UserRole.NATIONAL_OFFICER),
    ]

    created_officers = []
    for o in officers:
        user, created = User.objects.get_or_create(
            phone=o['phone'],
            defaults={**o, 'is_verified': True}
        )
        if created:
            user.set_password('officer123')
            user.save()
            print(f"  Created officer: {user.full_name}")
        created_officers.append(user)

    # ─── Citizens ─────────────────────────────────────────────────────────────
    citizens_data = [
        dict(phone='+255711111111', full_name='Amina Hassan',
             mtaa='Kariakoo', ward='Kariakoo', district='Ilala', region='Dar es Salaam'),
        dict(phone='+255722222222', full_name='John Makundi',
             mtaa='Mwananyamala', ward='Mwananyamala', district='Kinondoni', region='Dar es Salaam'),
        dict(phone='+255733333333', full_name='Fatuma Suleiman',
             mtaa='Temeke', ward='Temeke', district='Temeke', region='Dar es Salaam'),
        dict(phone='+255744444444', full_name='Peter Mwanga',
             mtaa='Mikocheni', ward='Mikocheni', district='Kinondoni', region='Dar es Salaam'),
        dict(phone='+255755555555', full_name='Grace Nyamizi',
             mtaa='Kimara', ward='Kimara', district='Ubungo', region='Dar es Salaam'),
    ]

    citizens = []
    for c in citizens_data:
        user, created = User.objects.get_or_create(
            phone=c['phone'],
            defaults={**c, 'is_verified': True}
        )
        if created:
            user.set_password('citizen123')
            user.save()
            print(f"  Created citizen: {user.full_name}")
        citizens.append(user)

    # ─── Complaints ───────────────────────────────────────────────────────────
    complaints_data = [
        dict(
            citizen=citizens[0],
            title='Barabara Imeharibiwa - Broken Road on Uhuru Street',
            description='Barabara ya Uhuru Street ina mashimo makubwa sana ambayo yanasababisha ajali nyingi. '
                        'The road has massive potholes causing daily accidents. Multiple vehicles have been damaged '
                        'and one motorcycle accident occurred last week. Urgent repair needed.',
            category=ComplaintCategory.INFRASTRUCTURE,
            status=ComplaintStatus.PENDING,
            current_level=GovernmentLevel.MTAA,
            mtaa='Kariakoo', ward='Kariakoo', district='Ilala', region='Dar es Salaam',
            upvotes=24, is_urgent=False, priority_score=24,
            submitted_at=timezone.now() - timedelta(days=3),
            last_action_at=timezone.now() - timedelta(days=3),
        ),
        dict(
            citizen=citizens[1],
            title='Maji Safi Hayapo - No Clean Water for 2 Weeks',
            description='Kata yetu haina maji safi kwa wiki mbili sasa. Our ward has had no clean water supply '
                        'for two weeks. Residents are forced to buy expensive water from vendors. '
                        'Children are missing school due to waterborne illnesses.',
            category=ComplaintCategory.WATER,
            status=ComplaintStatus.ESCALATED,
            current_level=GovernmentLevel.WARD,
            mtaa='Mwananyamala', ward='Mwananyamala', district='Kinondoni', region='Dar es Salaam',
            upvotes=87, is_urgent=True, priority_score=97,
            submitted_at=timezone.now() - timedelta(days=15),
            last_action_at=timezone.now() - timedelta(days=8),
        ),
        dict(
            citizen=citizens[2],
            title='Hospitali Haina Dawa - District Hospital Lacks Medicine',
            description='Hospitali ya Wilaya haina dawa za msingi kwa miezi miwili. '
                        'The district hospital has been out of essential medicines including antibiotics '
                        'and malaria drugs for two months. Patients are being turned away or asked to buy '
                        'medicine from private pharmacies they cannot afford.',
            category=ComplaintCategory.HEALTH,
            status=ComplaintStatus.IN_PROGRESS,
            current_level=GovernmentLevel.DISTRICT,
            mtaa='Temeke', ward='Temeke', district='Temeke', region='Dar es Salaam',
            upvotes=156, is_urgent=True, priority_score=166,
            submitted_at=timezone.now() - timedelta(days=45),
            last_action_at=timezone.now() - timedelta(days=5),
        ),
        dict(
            citizen=citizens[3],
            title='Taa za Mitaani Hazifanyi Kazi - Street Lights Not Working',
            description='Street lights in our area have been off for a month, creating serious security '
                        'concerns at night. Three robbery incidents have occurred in the dark streets. '
                        'Residents are afraid to walk at night.',
            category=ComplaintCategory.ELECTRICITY,
            status=ComplaintStatus.RESOLVED,
            current_level=GovernmentLevel.MTAA,
            mtaa='Mikocheni', ward='Mikocheni', district='Kinondoni', region='Dar es Salaam',
            upvotes=43, priority_score=43,
            submitted_at=timezone.now() - timedelta(days=20),
            last_action_at=timezone.now() - timedelta(days=2),
            resolved_at=timezone.now() - timedelta(days=2),
        ),
        dict(
            citizen=citizens[4],
            title='Shule ya Msingi Haina Madawati - Primary School Has No Desks',
            description='Shule ya msingi ya Kimara ina wanafunzi 400 lakini madawati ni 150 tu. '
                        'Kimara primary school has 400 students but only 150 desks. '
                        'Children are sitting on the floor or sharing desks 3-4 per desk.',
            category=ComplaintCategory.EDUCATION,
            status=ComplaintStatus.PENDING,
            current_level=GovernmentLevel.MTAA,
            mtaa='Kimara', ward='Kimara', district='Ubungo', region='Dar es Salaam',
            upvotes=62, priority_score=62,
            submitted_at=timezone.now() - timedelta(days=6),
            last_action_at=timezone.now() - timedelta(days=6),
        ),
    ]

    for cd in complaints_data:
        if not Complaint.objects.filter(
            citizen=cd['citizen'], title=cd['title']
        ).exists():
            complaint = Complaint.objects.create(**cd)
            print(f"  Created complaint: [{complaint.tracking_code}] {complaint.title[:50]}")

            # Add escalation history for escalated/district complaints
            if complaint.status in [ComplaintStatus.ESCALATED, ComplaintStatus.IN_PROGRESS] and \
               complaint.current_level in [GovernmentLevel.WARD, GovernmentLevel.DISTRICT]:

                if complaint.current_level == GovernmentLevel.WARD:
                    EscalationHistory.objects.create(
                        complaint=complaint,
                        from_level=GovernmentLevel.MTAA,
                        to_level=GovernmentLevel.WARD,
                        reason='Auto-escalated: No action taken within 7 days at Mtaa level.',
                        escalated_at=timezone.now() - timedelta(days=8),
                    )
                elif complaint.current_level == GovernmentLevel.DISTRICT:
                    EscalationHistory.objects.create(
                        complaint=complaint,
                        from_level=GovernmentLevel.MTAA,
                        to_level=GovernmentLevel.WARD,
                        reason='Auto-escalated: No action taken within 7 days at Mtaa level.',
                        escalated_at=timezone.now() - timedelta(days=38),
                    )
                    EscalationHistory.objects.create(
                        complaint=complaint,
                        from_level=GovernmentLevel.WARD,
                        to_level=GovernmentLevel.DISTRICT,
                        reason='Auto-escalated: No action taken within 14 days at Ward level.',
                        escalated_at=timezone.now() - timedelta(days=24),
                    )
                    # Add official comment
                    Comment.objects.create(
                        complaint=complaint,
                        author=created_officers[2],  # DC officer
                        content='We have contacted the Ministry of Health. Medicine supply delivery expected within 3 days.',
                        is_official=True,
                        is_internal=False,
                    )

    print("\nSeed data complete!")
    print("\nDemo accounts:")
    print("  Citizens:  +255711111111 to +255755555555  /  password: citizen123")
    print("  Officers:  +255700000001 to +255700000005  /  password: officer123")
    print("  Admin:     +255000000000                   /  password: admin123")
