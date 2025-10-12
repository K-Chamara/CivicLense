# 🎯 CivicLense - Complete User Flows

## Overview
This document outlines the complete user journey for all user types in the CivicLense platform.

---

## 👥 User Roles

### **1. Admin (System Administrator)**
- **Type**: Admin
- **Limit**: 1 user only
- **Color Theme**: 🔴 Red

### **2. Government Officers**
- **Finance Officer** - 🟢 Green (Limit: 1)
- **Procurement Officer** - 🟠 Orange (Limit: 1)
- **Anti-Corruption Officer** - 🟣 Purple (Limit: 3)

### **3. Public Users** (Unlimited)
- **Citizen/Taxpayer** - 🔵 Blue
- **Journalist/Media** - 🟦 Teal
- **Community Leader/Activist** - 🟦 Indigo
- **Researcher/Academic** - 🟪 Deep Purple
- **NGO/Private Contractor** - 🟤 Brown

---

## 📊 DETAILED USER FLOWS

---

## 1️⃣ **ADMIN FLOW** 🔴

### **Initial Setup:**
```
Admin Creation (One-Time) → Login → Admin Dashboard
```

### **Main User Journey:**
```
Login → Admin Dashboard → User Management → System Monitoring → Sign Out
```

### **Complete Admin Workflow:**

**A. User Account Management:**
```
Admin Dashboard
    ├── View All Users
    │   ├── Filter by Role
    │   ├── View User Details
    │   └── Check User Status
    │
    ├── Create Government Officers
    │   ├── Create Finance Officer (1 max)
    │   ├── Create Procurement Officer (1 max)
    │   └── Create Anti-Corruption Officers (3 max)
    │
    ├── Approve/Reject User Applications
    │   ├── Review Journalist Applications
    │   ├── Review Community Leader Applications
    │   ├── Review Researcher Applications
    │   └── Review NGO Applications
    │
    └── Manage User Status
        ├── Activate/Deactivate Accounts
        ├── Reset User Passwords
        └── Delete User Accounts
```

**B. System Management:**
```
System Monitoring
    ├── View System Statistics
    │   ├── Total Users by Role
    │   ├── Active Concerns
    │   ├── Budget Summary
    │   └── Tender Statistics
    │
    ├── Review Reports & Analytics
    │   ├── User Activity Reports
    │   ├── Concern Resolution Reports
    │   ├── Budget Utilization Reports
    │   └── System Health Reports
    │
    └── Manage Communities
        ├── View All Communities
        ├── Moderate Community Content
        └── Delete Inappropriate Communities
```

**Key Admin Features:**
- ✅ Full user management (create, edit, delete, approve)
- ✅ Role assignment and permissions
- ✅ System-wide statistics
- ✅ Government officer creation
- ✅ Public user approval
- ✅ Community moderation
- ✅ System reports generation

---

## 2️⃣ **FINANCE OFFICER FLOW** 🟢

### **Main User Journey:**
```
Login → 2FA/OTP Verification → Finance Dashboard → Budget Management → Reports → Sign Out
```

### **Complete Finance Officer Workflow:**

**A. Budget Management:**
```
Finance Dashboard
    ├── Upload Budget Data
    │   ├── Upload CSV/Excel Files
    │   ├── Review Budget Structure
    │   ├── Validate Data
    │   └── Publish Budget
    │
    ├── Manage Budget Categories
    │   ├── Create Main Categories
    │   ├── Add Subcategories
    │   ├── Define Budget Items
    │   └── Set Allocations
    │
    └── Track Budget Utilization
        ├── View Spending Summary
        ├── Monitor Category-wise Expenses
        ├── Check Remaining Funds
        └── Identify Overspending
```

**B. Financial Operations:**
```
Financial Management
    ├── Transaction Management
    │   ├── Record Expenses
    │   ├── Track Income
    │   ├── Manage Vendor Payments
    │   └── Review Transaction History
    │
    ├── Financial Reports
    │   ├── Generate Monthly Reports
    │   ├── Create Quarterly Analysis
    │   ├── Export Financial Data
    │   └── Share Reports with Admin
    │
    └── Audit Management
        ├── Prepare Audit Documents
        ├── Track Audit Requirements
        └── Respond to Audit Queries
```

**C. Analytics & Transparency:**
```
Budget Analytics
    ├── View Spending Trends
    ├── Analyze Category Performance
    ├── Compare Budget vs Actual
    ├── Generate Visual Reports
    └── Track Financial Efficiency
```

**Key Finance Officer Features:**
- ✅ Budget upload (CSV/Excel)
- ✅ Budget category management
- ✅ Transaction recording
- ✅ Financial report generation
- ✅ Expense tracking
- ✅ Vendor payment management
- ✅ Budget analytics & visualization
- ✅ Audit trail management
- ✅ Public transparency reporting

**Security:**
- 🔐 2FA/OTP required for login
- 🔐 High security level
- 🔐 Action logging

---

## 3️⃣ **PROCUREMENT OFFICER FLOW** 🟠

### **Main User Journey:**
```
Login → 2FA/OTP Verification → Procurement Dashboard → Tender Management → Vendor Management → Sign Out
```

### **Complete Procurement Officer Workflow:**

**A. Tender Management:**
```
Procurement Dashboard
    ├── Create New Tenders
    │   ├── Define Tender Details
    │   ├── Set Requirements
    │   ├── Upload Documents
    │   ├── Set Deadline
    │   └── Publish Tender
    │
    ├── Manage Active Tenders
    │   ├── View Tender List
    │   ├── Update Tender Status
    │   ├── Extend Deadlines
    │   └── Close Tenders
    │
    └── Bid Evaluation
        ├── Review Submitted Bids
        ├── Compare Bid Proposals
        ├── Evaluate Bidders
        ├── Award Tender
        └── Notify Winners/Losers
```

**B. Vendor Management:**
```
Vendor Operations
    ├── Vendor Registration
    │   ├── Review Vendor Applications
    │   ├── Verify Credentials
    │   ├── Approve/Reject Vendors
    │   └── Maintain Vendor Database
    │
    ├── Vendor Performance
    │   ├── Track Vendor Ratings
    │   ├── Monitor Contract Compliance
    │   ├── Handle Complaints
    │   └── Generate Vendor Reports
    │
    └── Vendor Communications
        ├── Send Notifications
        ├── Answer Queries
        └── Update Vendor Status
```

**C. Contract & Project Management:**
```
Contract Management
    ├── Award Contracts
    │   ├── Prepare Contract Documents
    │   ├── Define Terms & Conditions
    │   └── Finalize Agreements
    │
    ├── Monitor Project Progress
    │   ├── Track Milestones
    │   ├── Review Deliverables
    │   ├── Process Payments
    │   └── Handle Disputes
    │
    └── Project Completion
        ├── Final Inspection
        ├── Release Final Payments
        ├── Generate Completion Reports
        └── Archive Project Data
```

**D. Analytics & Reporting:**
```
Procurement Analytics
    ├── View Tender Statistics
    ├── Monitor Bid Participation
    ├── Track Contract Values
    ├── Analyze Vendor Performance
    └── Generate Procurement Reports
```

**Key Procurement Officer Features:**
- ✅ Tender creation & management
- ✅ Bid evaluation system
- ✅ Vendor registration & approval
- ✅ Contract management
- ✅ Purchase order processing
- ✅ Project milestone tracking
- ✅ Vendor performance monitoring
- ✅ Procurement analytics
- ✅ Public tender transparency

**Security:**
- 🔐 2FA/OTP required for login
- 🔐 High security level
- 🔐 Audit trail for all actions

---

## 4️⃣ **ANTI-CORRUPTION OFFICER FLOW** 🟣

### **Main User Journey:**
```
Login → 2FA/OTP Verification → Anti-Corruption Dashboard → Concern Management → Investigation → Resolution → Sign Out
```

### **Complete Anti-Corruption Officer Workflow:**

**A. Concern Management:**
```
Anti-Corruption Dashboard
    ├── View All Concerns
    │   ├── Pending Concerns
    │   ├── Under Investigation
    │   ├── Resolved Concerns
    │   └── Archived Cases
    │
    ├── AI-Powered Analysis
    │   ├── Auto-Priority Detection
    │   ├── Sentiment Analysis
    │   ├── Duplicate Detection
    │   └── Pattern Recognition
    │
    └── Concern Assignment
        ├── Assign to Officers
        ├── Set Priority Levels
        ├── Add Investigation Tags
        └── Track Status Updates
```

**B. AI Investigation Tools** (🧠 Brain Icon):
```
AI Assistant Features
    ├── 🎯 Risk Assessment
    │   ├── Identify Investigation Risks
    │   ├── Analyze Risk Levels
    │   ├── Generate Mitigation Strategies
    │   └── Recommend Security Measures
    │
    ├── 🔍 Evidence Analysis
    │   ├── Evaluate Evidence Quality
    │   ├── Rate Evidence Strength
    │   ├── Suggest Evidence Collection Plan
    │   └── Identify Missing Evidence
    │
    ├── 📋 Investigation Strategy
    │   ├── Generate Multi-Phase Plan
    │   ├── Define Investigation Steps
    │   ├── Set Timeline & Milestones
    │   └── Assign Resources
    │
    ├── 🔄 Duplicate Detection
    │   ├── Find Similar Concerns
    │   ├── Identify Patterns
    │   ├── Link Related Cases
    │   └── Merge Duplicates
    │
    └── ✉️ Response Generator
        ├── Draft Citizen Responses
        ├── Generate Status Updates
        ├── Create Official Letters
        └── Prepare Reports
```

**C. Investigation Process:**
```
Investigation Workflow
    ├── Initial Review
    │   ├── Review Concern Details
    │   ├── Analyze AI Insights
    │   ├── Check Evidence
    │   └── Assign Priority
    │
    ├── Active Investigation
    │   ├── Gather Additional Evidence
    │   ├── Interview Witnesses
    │   ├── Document Findings
    │   └── Update Status
    │
    ├── Case Resolution
    │   ├── Prepare Investigation Report
    │   ├── Make Recommendations
    │   ├── Notify Concerned Parties
    │   └── Close Case
    │
    └── Follow-Up
        ├── Monitor Implementation
        ├── Track Compliance
        └── Archive Case Files
```

**D. Community Moderation:**
```
Community Management
    ├── Create Communities
    │   ├── Define Community Purpose
    │   ├── Set Guidelines
    │   └── Publish Community
    │
    ├── Moderate Communities
    │   ├── Review Posts (Gemini AI)
    │   ├── Check Guideline Violations
    │   ├── Remove Inappropriate Content
    │   └── Delete Non-Compliant Communities
    │
    └── Member Management
        ├── View Community Members
        ├── Handle Member Reports
        └── Manage Community Status
```

**E. Reporting & Analytics:**
```
Reports & Analytics
    ├── Case Statistics
    ├── Resolution Rate Analysis
    ├── Corruption Pattern Reports
    ├── Investigation Timeline Reports
    └── Monthly Performance Reports
```

**Key Anti-Corruption Officer Features:**
- ✅ **AI-powered concern analysis** (Gemini AI)
- ✅ **5 AI investigation tools** (Risk, Evidence, Strategy, Duplicates, Response)
- ✅ Concern priority management
- ✅ Investigation case management
- ✅ Evidence tracking & analysis
- ✅ Whistleblower portal
- ✅ Community creation & moderation
- ✅ AI-powered content moderation (Gemini)
- ✅ Community deletion powers
- ✅ Compliance monitoring
- ✅ Report generation
- ✅ Pattern detection

**Security:**
- 🔐 2FA/OTP required for login
- 🔐 High security level
- 🔐 Secure evidence handling
- 🔐 Whistleblower protection

---

## 5️⃣ **CITIZEN/TAXPAYER FLOW** 🔵

### **Main User Journey:**
```
Register → Email Verification → Login → Citizen Dashboard → Access Services → Monitor Activities → Sign Out
```

### **Complete Citizen Workflow:**

**A. Registration & Setup:**
```
Registration Process
    ├── Enter Personal Details
    ├── Select "Citizen" Role
    ├── Create Password
    ├── Verify Email
    └── Complete Profile
```

**B. Budget Monitoring:**
```
Budget Transparency
    ├── View Government Budgets
    │   ├── Browse Budget Categories
    │   ├── View Subcategories
    │   ├── Check Budget Items
    │   └── See Allocations
    │
    ├── Track Public Spending
    │   ├── Monitor Expenditures
    │   ├── View Transaction History
    │   ├── Check Budget Utilization
    │   └── Download Reports
    │
    └── Budget Analytics
        ├── View Spending Charts
        ├── Compare Allocations
        ├── Track Trends
        └── Export Data
```

**C. Tender Monitoring:**
```
Tender Tracking
    ├── View Active Tenders
    │   ├── Browse Open Tenders
    │   ├── View Tender Details
    │   ├── Check Requirements
    │   └── Download Documents
    │
    ├── Track Awarded Tenders
    │   ├── See Contract Winners
    │   ├── View Contract Values
    │   ├── Monitor Project Progress
    │   └── Check Completion Status
    │
    └── Tender Analytics
        ├── View Tender Statistics
        └── Track Tender History
```

**D. Raise Concerns:** (🧠 AI-Powered)
```
Concern Submission
    ├── Create New Concern
    │   ├── Enter Title
    │   ├── Write Description (100+ chars)
    │   ├── Select Category (AI-Suggested)
    │   ├── Add Evidence (Photos/Docs)
    │   └── Choose Anonymity Option
    │
    ├── AI Analysis (Real-time)
    │   ├── 🎯 Priority Detection (High/Med/Low)
    │   ├── 😊 Sentiment Analysis (Pos/Neg/Neu)
    │   ├── 🏷️ Topic Extraction
    │   ├── 📊 Engagement Score (Real Data)
    │   │   └── Shows community support %
    │   ├── ✅ Quality Check
    │   └── 💡 Category Suggestion
    │
    └── Submit Concern
        ├── Review AI Insights
        ├── Confirm Submission
        ├── Receive Tracking ID
        └── Get Confirmation Email
```

**E. Monitor Concerns:**
```
Concern Tracking
    ├── View My Concerns
    │   ├── Check Status Updates
    │   ├── View Officer Responses
    │   ├── Track Investigation Progress
    │   └── See Resolution Status
    │
    ├── View Public Concerns
    │   ├── Browse All Concerns
    │   ├── Filter by Category
    │   ├── Support Similar Concerns
    │   └── Add Comments
    │
    └── Receive Notifications
        ├── Status Change Alerts
        ├── Officer Response Alerts
        └── Resolution Notifications
```

**F. Community Engagement:**
```
Community Features
    ├── Join Communities
    │   ├── Browse Available Communities
    │   ├── View Community Details
    │   ├── Join Communities
    │   └── View Member List
    │
    ├── Participate in Communities
    │   ├── Create Posts
    │   ├── Share Content
    │   ├── Comment on Posts
    │   └── Like & Engage
    │
    └── Leave Communities
        ├── View Joined Communities
        ├── Leave Community (3-dot menu)
        └── Receive Confirmation
```

**G. News & Media:**
```
Media Hub
    ├── Read News Articles
    │   ├── Browse Latest News
    │   ├── Search Articles
    │   ├── Filter by Category
    │   └── View Article Details
    │
    ├── Engage with Content
    │   ├── Like Articles
    │   ├── Comment on Articles
    │   ├── Share to Community
    │   └── Bookmark Articles
    │
    └── Media Transparency
        ├── View Government Reports
        └── Access Public Documents
```

**Key Citizen Features:**
- ✅ **AI-powered concern submission** (Gemini)
- ✅ **Real-time engagement score** (based on similar concerns)
- ✅ **AI quality check & suggestions**
- ✅ Budget transparency access
- ✅ Tender monitoring
- ✅ Concern tracking with notifications
- ✅ Community participation
- ✅ News & media access
- ✅ Anonymous reporting option
- ✅ Evidence upload (photos/documents)
- ✅ Support similar concerns
- ✅ Download public reports

---

## 6️⃣ **JOURNALIST/MEDIA FLOW** 🟦

### **Main User Journey:**
```
Register → Submit Credentials → Await Admin Approval → Login → Journalist Dashboard → Publish Content → Track Engagement → Sign Out
```

### **Complete Journalist Workflow:**

**A. Account Setup:**
```
Registration & Verification
    ├── Register with Journalist Role
    ├── Submit Credentials
    │   ├── Press Card/ID
    │   ├── Media Organization Details
    │   └── Portfolio/Work Samples
    │
    ├── Admin Review
    │   └── Await Approval (Pending Status)
    │
    └── Account Activation
        └── Receive Approval Notification
```

**B. Content Creation:**
```
Publish Reports
    ├── Create News Articles
    │   ├── Write Article Content
    │   ├── Add Title & Description
    │   ├── Upload Featured Image
    │   ├── Add Tags & Categories
    │   └── Add Source Links
    │
    ├── Write Transparency Reports
    │   ├── Investigate Public Data
    │   ├── Analyze Budget Reports
    │   ├── Review Tender Information
    │   ├── Create Data Visualizations
    │   └── Cite Sources
    │
    └── Publish Content
        ├── Preview Article
        ├── Publish to Public
        └── Share to Communities
```

**C. Data Access:**
```
Access Public Data
    ├── Budget Data
    │   ├── Download Budget Reports
    │   ├── Access Spending Data
    │   ├── Export Financial Data
    │   └── View Historical Budgets
    │
    ├── Tender Information
    │   ├── View All Tenders
    │   ├── Track Contract Awards
    │   ├── Monitor Project Progress
    │   └── Access Contract Documents
    │
    ├── Concern Data (Public)
    │   ├── View Public Concerns
    │   ├── Track Resolution Rates
    │   ├── Analyze Concern Patterns
    │   └── Create Reports
    │
    └── Public Reports & Analytics
        ├── Government Reports
        ├── Transparency Reports
        └── Statistical Data
```

**D. Community Engagement:**
```
Community Interaction
    ├── Join Communities
    ├── Share News Articles
    ├── Participate in Discussions
    ├── Engage with Citizens
    └── Leave Communities
```

**E. Content Management:**
```
Manage Publications
    ├── View Published Articles
    ├── Edit Existing Articles
    ├── Track Article Analytics
    │   ├── View Count
    │   ├── Like Count
    │   ├── Comment Count
    │   └── Share Count
    │
    └── Manage Comments
        ├── Moderate Comments
        └── Respond to Readers
```

**Key Journalist Features:**
- ✅ **Admin approval required**
- ✅ Publish news articles
- ✅ Create transparency reports
- ✅ Access all public data
- ✅ Download budget & tender data
- ✅ Analyze public spending
- ✅ Share articles to communities
- ✅ Track article engagement
- ✅ Professional media tools
- ✅ Source citation system
- ✅ Data visualization tools

---

## 7️⃣ **COMMUNITY LEADER/ACTIVIST FLOW** 🟦

### **Main User Journey:**
```
Register → Submit Credentials → Await Admin Approval → Login → Community Leader Dashboard → Create/Manage Communities → Organize Initiatives → Sign Out
```

### **Complete Community Leader Workflow:**

**A. Account Setup:**
```
Registration & Verification
    ├── Register with Community Leader Role
    ├── Submit Credentials
    │   ├── Community Organization Details
    │   ├── Leadership Proof
    │   └── References
    │
    ├── Admin Review
    │   └── Await Approval
    │
    └── Account Activation
        └── Receive Approval Notification
```

**B. Community Management:**
```
Create & Manage Communities
    ├── Create New Community
    │   ├── Define Community Name
    │   ├── Write Description
    │   ├── Select Category
    │   ├── Set Privacy (Public/Private)
    │   ├── Upload Thumbnail
    │   └── Set Community Guidelines
    │
    ├── Manage Created Communities
    │   ├── View Community Dashboard
    │   ├── Edit Community Details
    │   ├── Update Guidelines
    │   └── Delete Community (Creator Only)
    │
    ├── Member Management
    │   ├── View All Members
    │   ├── Promote to Admin
    │   ├── Remove Members
    │   └── Handle Join Requests
    │
    └── Content Moderation
        ├── Review Posts
        ├── Approve/Reject Posts
        ├── Pin Important Posts
        ├── Remove Inappropriate Content
        └── Ban Violating Users
```

**C. Community Engagement:**
```
Community Activities
    ├── Create Posts
    │   ├── Write Updates
    │   ├── Share News
    │   ├── Upload Photos
    │   └── Add Tags
    │
    ├── Organize Events
    │   ├── Create Event Posts
    │   ├── Set Event Details
    │   └── Track RSVPs
    │
    ├── Moderate Discussions
    │   ├── Monitor Comments
    │   ├── Respond to Members
    │   └── Guide Conversations
    │
    └── Community Analytics
        ├── View Member Growth
        ├── Track Post Engagement
        ├── Monitor Activity Trends
        └── Generate Reports
```

**D. Civic Participation:**
```
Civic Engagement
    ├── Raise Concerns (AI-Powered)
    ├── Monitor Public Spending
    ├── Track Tenders
    ├── Join Other Communities
    ├── Support Citizen Concerns
    └── Access Public Data
```

**E. Community Leadership:**
```
Leave/Remove Communities
    ├── Leave Communities (As Member)
    │   └── 3-dot menu → Leave Community
    │
    └── Remove Community (As Creator)
        ├── 3-dot menu → Remove Community
        ├── Provide Reason
        ├── Confirm Deletion
        └── Notify All Members
```

**Key Community Leader Features:**
- ✅ **Admin approval required**
- ✅ **Create unlimited communities**
- ✅ **Full community management powers**
- ✅ Member promotion to admin
- ✅ Content moderation tools
- ✅ Post approval system
- ✅ Community analytics
- ✅ Event organization
- ✅ Member management
- ✅ **Delete own communities only**
- ✅ **Leave communities as member**
- ✅ All citizen features included

---

## 8️⃣ **RESEARCHER/ACADEMIC FLOW** 🟪

### **Main User Journey:**
```
Register → Submit Credentials → Await Admin Approval → Login → Researcher Dashboard → Access Research Data → Generate Reports → Sign Out
```

### **Complete Researcher Workflow:**

**A. Account Setup:**
```
Registration & Verification
    ├── Register with Researcher Role
    ├── Submit Credentials
    │   ├── Academic Institution
    │   ├── Research ID
    │   ├── Publications/CV
    │   └── Research Proposal
    │
    ├── Admin Review
    │   └── Await Approval
    │
    └── Account Activation
        └── Receive Approval Notification
```

**B. Data Access & Analysis:**
```
Research Data Access
    ├── Access All Public Data
    │   ├── Budget Data (Historical)
    │   ├── Tender Data (Complete)
    │   ├── Concern Data (Anonymized)
    │   ├── Transaction Data
    │   └── Statistical Reports
    │
    ├── Advanced Analytics
    │   ├── Data Filtering
    │   ├── Custom Queries
    │   ├── Trend Analysis
    │   ├── Pattern Recognition
    │   └── Comparative Studies
    │
    └── Data Export
        ├── Export to CSV/Excel
        ├── Export to JSON
        ├── Generate PDF Reports
        └── Download Raw Data
```

**C. Research Tools:**
```
Research Features
    ├── Create Research Reports
    │   ├── Data Visualization
    │   ├── Statistical Analysis
    │   ├── Graphs & Charts
    │   └── Citation Management
    │
    ├── Collaborate with Others
    │   ├── Share Research Data
    │   ├── Join Research Communities
    │   └── Co-author Reports
    │
    └── Publish Findings
        ├── Publish Research Papers
        ├── Share to Communities
        └── Submit to Media Hub
```

**D. Public Engagement:**
```
Civic Participation
    ├── Monitor Public Spending
    ├── Track Government Tenders
    ├── Raise Research-Based Concerns
    ├── Join/Leave Communities
    ├── Access News & Media
    └── Support Citizen Concerns
```

**Key Researcher Features:**
- ✅ **Admin approval required**
- ✅ **Access to complete historical data**
- ✅ Advanced data analytics tools
- ✅ Custom data queries
- ✅ Multiple export formats
- ✅ Data visualization tools
- ✅ Statistical analysis features
- ✅ Research report generation
- ✅ Anonymized concern data access
- ✅ All citizen features included
- ✅ Join/leave communities

---

## 9️⃣ **NGO/PRIVATE CONTRACTOR FLOW** 🟤

### **Main User Journey:**
```
Register → Submit Credentials → Await Admin Approval → Login → NGO Dashboard → Track Projects → Bid on Tenders → Monitor Contracts → Sign Out
```

### **Complete NGO/Contractor Workflow:**

**A. Account Setup:**
```
Registration & Verification
    ├── Register with NGO/Contractor Role
    ├── Submit Credentials
    │   ├── Organization Registration
    │   ├── Business License
    │   ├── Tax Documents
    │   ├── Company Profile
    │   └── Project Portfolio
    │
    ├── Admin Review
    │   └── Await Approval
    │
    └── Account Activation
        └── Receive Approval Notification
```

**B. Tender Management:**
```
Tender Participation
    ├── Browse Available Tenders
    │   ├── View All Open Tenders
    │   ├── Filter by Category
    │   ├── Search Tenders
    │   └── View Tender Details
    │
    ├── Bid Submission
    │   ├── Download Tender Documents
    │   ├── Prepare Bid Proposal
    │   ├── Upload Bid Documents
    │   ├── Submit Technical Proposal
    │   ├── Submit Financial Proposal
    │   └── Track Bid Status
    │
    ├── Bid Tracking
    │   ├── View Submitted Bids
    │   ├── Check Evaluation Status
    │   ├── Receive Award Notifications
    │   └── Track Bid History
    │
    └── Contract Award
        ├── Receive Award Notice
        ├── Sign Contract
        └── Begin Project
```

**C. Project Management:**
```
Contract & Project Tracking
    ├── Active Contracts
    │   ├── View Contract Details
    │   ├── Track Project Milestones
    │   ├── Submit Progress Reports
    │   ├── Upload Deliverables
    │   └── Request Payments
    │
    ├── Project Execution
    │   ├── Update Project Status
    │   ├── Manage Resources
    │   ├── Handle Change Requests
    │   ├── Communicate with Officers
    │   └── Resolve Issues
    │
    └── Project Completion
        ├── Submit Final Deliverables
        ├── Request Final Payment
        ├── Receive Completion Certificate
        └── Close Project
```

**D. Business Operations:**
```
Contractor Tools
    ├── Vendor Profile Management
    │   ├── Update Company Details
    │   ├── Add Certifications
    │   ├── Update Capabilities
    │   └── Manage Documents
    │
    ├── Financial Management
    │   ├── Track Payments
    │   ├── View Payment History
    │   ├── Submit Invoices
    │   └── Download Receipts
    │
    └── Performance Tracking
        ├── View Performance Ratings
        ├── Read Feedback
        ├── Track Success Rate
        └── Generate Performance Reports
```

**E. Civic Participation:**
```
Public Engagement
    ├── Monitor Public Budgets
    ├── Track Government Spending
    ├── Raise Concerns
    ├── Join/Leave Communities
    ├── Access Public Data
    └── View Transparency Reports
```

**Key NGO/Contractor Features:**
- ✅ **Admin approval required**
- ✅ Browse & bid on tenders
- ✅ Submit technical & financial proposals
- ✅ Track bid evaluation status
- ✅ Receive award notifications
- ✅ Contract management tools
- ✅ Project milestone tracking
- ✅ Payment request system
- ✅ Performance rating system
- ✅ Vendor profile management
- ✅ Document management
- ✅ All citizen features included
- ✅ Join/leave communities

---

## 📊 FEATURE COMPARISON TABLE

| Feature | Admin | Finance | Procurement | Anti-Corr | Citizen | Journalist | Comm Leader | Researcher | NGO |
|---------|-------|---------|-------------|-----------|---------|------------|-------------|------------|-----|
| **User Management** | ✅ Full | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Approve Users** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Budget Upload** | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Budget View** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Create Tenders** | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Bid on Tenders** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **View Tenders** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Raise Concerns** | ✅ | ✅ | ✅ | ✅ | ✅ AI | ✅ | ✅ AI | ✅ | ✅ |
| **Manage Concerns** | ❌ | ❌ | ❌ | ✅ AI | ❌ | ❌ | ❌ | ❌ | ❌ |
| **AI Tools (5)** | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Create Communities** | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| **Join Communities** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Leave Communities** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Delete Any Community** | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ | Own Only | ❌ | ❌ |
| **Publish Articles** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| **Research Data** | ✅ | ✅ | ✅ | ✅ | View | ✅ | View | ✅ Full | View |
| **2FA/OTP** | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Approval Needed** | No | Created | Created | Created | No | Yes | Yes | Yes | Yes |

---

## 🔐 SECURITY & AUTHENTICATION

### **Admin:**
- One-time admin creation
- Standard login
- Full system access

### **Government Officers:**
- Created by admin
- 2FA/OTP authentication required
- High security level
- Action logging
- Secure credential storage

### **Public Users:**
- Self-registration
- Email verification required
- Some roles need admin approval:
  - ✅ **Journalist** - Needs approval
  - ✅ **Community Leader** - Needs approval
  - ✅ **Researcher** - Needs approval
  - ✅ **NGO/Contractor** - Needs approval
  - ❌ **Citizen** - No approval needed

### **Community Features:**
- **Create**: Admin, Anti-Corruption Officers, Community Leaders
- **Join**: All users
- **Leave**: All members (3-dot menu)
- **Delete**: 
  - Admin: Any community
  - Anti-Corruption Officers: Any community
  - Community Leaders: Own communities only

---

## 🧠 AI FEATURES

### **For Citizens (Raise Concern):**
- ✅ **Real-time Engagement Score** (Gemini AI)
- ✅ **Smart Category Suggestion** (Gemini AI)
- ✅ **Quality Check** (Gemini AI)
- ✅ **Priority Detection** (Gemini AI)
- ✅ **Sentiment Analysis** (Gemini AI)
- ✅ **Topic Extraction** (Gemini AI)

### **For Anti-Corruption Officers:**
- ✅ **Risk Assessment** (Gemini AI)
- ✅ **Evidence Analysis** (Gemini AI)
- ✅ **Investigation Strategy** (Gemini AI)
- ✅ **Duplicate Detection** (Gemini AI)
- ✅ **Response Generator** (Gemini AI)
- ✅ **Community Content Moderation** (Gemini AI)

---

## 📱 COMMON FEATURES (All Users)

- ✅ News & Media Hub
- ✅ View Public Concerns
- ✅ View Government Budgets
- ✅ Track Government Tenders
- ✅ Join/Leave Communities
- ✅ Community Participation
- ✅ Push Notifications
- ✅ Profile Management
- ✅ Language Selection (English, Sinhala, Tamil)
- ✅ Search Functionality
- ✅ Multilingual Support

---

## 🎯 QUICK REFERENCE

### **Authentication Required:**
- 2FA/OTP: Finance, Procurement, Anti-Corruption Officers
- Email Verification: All users
- Admin Approval: Journalist, Community Leader, Researcher, NGO

### **Can Create Communities:**
- ✅ Admin
- ✅ Anti-Corruption Officers
- ✅ Community Leaders

### **Can Delete Communities:**
- ✅ Admin (any community)
- ✅ Anti-Corruption Officers (any community)
- ✅ Community Leaders (own communities only)

### **Can Leave Communities:**
- ✅ All users (if they are members)

### **AI-Powered Features:**
- 🧠 Concern submission (Citizens)
- 🧠 5 Investigation tools (Anti-Corruption Officers)
- 🧠 Content moderation (Anti-Corruption Officers)

---

## 📞 SUPPORT & HELP

For questions or issues:
- 📧 Contact admin
- 📱 In-app support
- 📚 User guides available in app

---

**Last Updated:** October 2025
**Version:** 1.0
**Platform:** CivicLense - Government Transparency Platform

