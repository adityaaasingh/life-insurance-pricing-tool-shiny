# life-insurance-pricing-tool-shiny

Live App: 
https://adityaaasingh.shinyapps.io/life-insurance-pricing-tool-shiny/


Project Overview:

This project is an interactive life insurance pricing tool built in R and Shiny, using official Australian Government Actuary (AGA) Life Tables (ALT 2020–22).

The app allows users to:
- Price multiple types of life insurance products
- Choose between Ultimate and Select mortality
- Apply expenses
- Include bonus and inflation
- Compare single vs level premiums
- Visualise policy reserves over time

This demonstrates actuarial modelling, pricing mechanics, and deployment of a production-ready Shiny application.


What Is Being Modelled?:

The app prices traditional life insurance products using:
- Discrete yearly mortality
- Australian Life Tables (AGA ALT 2020–22)
- Discounting at a user-selected interest rate
- Prospective reserve calculations

All calculations are performed dynamically based on user inputs.


Policy Types Explained:
- Pure Endowment
   - Pays a benefit only if the policyholder survives to the end of the term.
   - Example:
     10-year policy
     Pays $100,000 if alive at year 10
     Pays nothing if death occurs before year 10
     Used for savings-style products.

- Term Assurance
  - Pays a benefit only if death occurs during the term.
  - Example:
    10-year policy
    Pays $100,000 if death occurs within 10 years
    Pays nothing if the insured survives the term
    Used for temporary protection

- Endowment Assurance
  - Combination of Term Assurance + Pure Endowment.
    - Pays:
      If death occurs during the term → death benefit
      If alive at end of term → survival benefit
      Used for savings and protection combined.

- Whole Life Assurance
  - Pays a benefit whenever death occurs (up to age 100 in this model).
  - There is no fixed term, coverage lasts for life.
 

Mortality Types
- Ultimate Mortality
  - Standard life table mortality rates for each age.

- Select Mortality:
  - Assumes improved mortality for newly insured individuals for a short period (selection effect).

  - Selection effect:
    - When someone applies for life insurance, they usually undergo:
      -  Medical underwriting
      -  Health questionnaires
      -  Risk assessment
    Higher-risk applicants may be declined or charged extra, newly issued policies tend to have lower mortality rates in the early years.
  
   - User can choose:
    - Select period (years)
    - Selection factor (mortality reduction)


Expenses Included:
- The app allows modelling:
  - Initial expenses (at issue, includes underwriting cost, medical assessments, commissions, admin)
  - Renewal expenses (each premium payment, such as admin cost, policy servicing, billing cost)
  - Claim expenses (added to benefit, includes claims processing, legal costs, admin)

- Gross premiums are calculated using the equivalence principle including expenses.

- In the model:
  - Claim expenses are added as a proportion of the benefit amount.
  - This increases the expected present value of benefits.


Bonus & Inflation:
- Users may apply:
  - Annual bonus rate (increasing benefit)
  - Inflation rate (benefit escalation)

- These adjustments apply to death benefits over time.

Reserves:
- The app calculates prospective reserves:
  - Reserve=EPV(FutureBenefits)−EPV(FuturePremiums)

- Displayed as:
  - Reserve plot over time
  - Key reserve values (t = 0, 1, 2, 3, T-1, T)

-  Endpoint conventions:
  - Pure Endowment / Endowment → reserve at maturity equals benefit
  - Term / Whole Life → reserve after final payment is 0















