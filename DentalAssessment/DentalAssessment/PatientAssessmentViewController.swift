//
//  CaseSheetViewController.swift
//  DentalAssessment
//
//  Created by student on 24/10/19.
//  Copyright © 2019 student. All rights reserved.
//

import Foundation
import UIKit
import Eureka
import SuggestionRow
import Firebase
import CodableFirebase

class CaseSheetViewController: FormViewController{
    
    var ref : DatabaseReference?
    var dbHandle : DatabaseHandle?
    
    var allowEdits = true
    var teethStatus = ""
    let teethStatuses = ["Decayed (D)", "Decayed with pulpal involvement (Pl)", "Root stump (RS)", "Missing (M)", "Filled (F)", "Mobility (Mo)", "Fracture (#)", "Prosthetic crown (C)", "Removable Partial Denture (RPD)", "Fixed partial denture (FPD)", "Attrition (AT)", "Abrasion (AB)", "Erosion (ER)"]
    let teethStatusesShort = ["D", "Pl", "RS", "M", "F", "Mo", "#", "C", "RPD", "FPD", "AT", "AB", "ER"]
    let deptList = [
            "2. Conservative Dentistry",
            "3. Periodontics",
            "4. Oral & Maxillofacial Surgery",
            "5. Prosthodontics",
            "6. Pedodontics",
            "7. Orthodontics"
        ]
    var treatmentsSection: MultivaluedSection = MultivaluedSection()
    var drugsSection: MultivaluedSection = MultivaluedSection()
    var deptVisitPriority: MultivaluedSection = MultivaluedSection()
    var teethViewRow = TeethViewRow()
    var caseSheet = CaseSheet()
    var patient = Patient()
    let editSwitch = UISwitch()
    let pid = "312" //set the value of pid
    var defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        
        ref = Database.database().reference()
        
        // patient.id = pid //set the value which is passed
        caseSheet.pid = patient.id
        print(patient.id)
        
        let editLabel = UILabel()
        editLabel.text = "Edit"
        editSwitch.addTarget(self, action: #selector(editButtonPushed(_:)), for: .touchUpInside)
        editSwitch.isOn = allowEdits
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: editSwitch), UIBarButtonItem(customView: editLabel)]
        super.viewDidLoad()
        print("here")
        print(self.allowEdits)
        populateForm()
        self.navigationItem.largeTitleDisplayMode = .never
        
        updateEditMode()
    }

    func populateForm(){
        
        ref = Database.database().reference()
        
        form.removeAll()
        // MARK: - Personal Details
        form +++ Section("Personal Details")
            <<< TextRow() { row in
                row.title = "Name"
                row.placeholder = "John Doe"
                row.value = self.patient.name
                var rules = RuleSet<String>()
                rules.add(rule: RuleRequired())
                row.add(ruleSet: rules)
                row.cellUpdate {(cell, row) in
                    if !row.isValid {
                      cell.titleLabel?.textColor = .red
                    }
                }
                //row.disabled = Condition(booleanLiteral: self.allowEdits)
                }.onChange({ textrow in
                    guard let name = textrow.value else {return}
                    self.patient.name = name
                    
                })
            <<< TextRow() { row in
                row.title = "Age"
                row.placeholder = "25"
                if patient.age > 0 {
                    row.value = String(patient.age)
                }
                var rules = RuleSet<String>()
                rules.add(rule: RuleRequired())
                row.add(ruleSet: rules)
                row.cellUpdate {(cell, row) in
                    if !row.isValid {
                      cell.titleLabel?.textColor = .red
                    }
                }
                }.onChange({ textrow in
                    guard let age = Int(textrow.value ?? "") else {return}
    
                    self.patient.age = age
                })
            <<< SegmentedRow<String>() { row in
                row.title = "Sex"
                row.options = ["Male","Female"]
                var rules = RuleSet<String>()
                rules.add(rule: RuleRequired())
                row.add(ruleSet: rules)
                row.cellUpdate {(cell, row) in
                    if !row.isValid {
                      cell.titleLabel?.textColor = .red
                    }
                }
                if patient.sex == 0 || patient.sex == 1 {
                    row.value = row.options?[patient.sex]
                }
                }.cellSetup { cell, _ in
                    guard let titleLabel = cell.titleLabel else {return}
                    cell.segmentedControl.widthAnchor.constraint(equalTo: titleLabel.widthAnchor).isActive = true
                }.onChange({ segmentedRow in
                    guard let sex = segmentedRow.value else {return}
                    switch(sex){
                    case "Male":
                        self.patient.sex = 0
                    default:
                        self.patient.sex = 1
                    }

                })
            <<< PhoneRow() { row in
                row.title = "Phone"
                row.placeholder = "+91 1234567890"
                row.value = self.patient.phone
                var rules = RuleSet<String>()
                rules.add(rule: RuleRequired())
                row.add(ruleSet: rules)
                row.cellUpdate {(cell, row) in
                    if !row.isValid {
                      cell.titleLabel?.textColor = .red
                    }
                }
                }.onChange({ textrow in
                    guard let phone = textrow.value else {return}
                    self.patient.phone = phone
                })
            <<< LabelRow {row in
                row.title = "Address"
            }
            <<< TextAreaRow { row in
                row.title = "Address"
                row.placeholder = "Street Address\nLocality\nCity, State\nPincode"
                row.value = self.patient.address
                }.onChange({ textrow in
                    guard let addr = textrow.value else {return}
                    self.patient.address = addr
                })
            
            // MARK: - Assessment details
            +++ Section("Assessment")
            <<< TextRow() { row in
                row.title = "Hospital Number"
                row.placeholder = "123"
                var rules = RuleSet<String>()
                rules.add(rule: RuleRequired())
                row.add(ruleSet: rules)
                row.cellUpdate {(cell, row) in
                    if !row.isValid {
                      cell.titleLabel?.textColor = .red
                    }
                }
                if self.caseSheet.hospitalNum > 0 {
                    row.value = String(self.caseSheet.hospitalNum)
                }
                }.onChange({ textrow in
                    guard let num = Int(textrow.value ?? "") else {return}
                    self.caseSheet.hospitalNum = num
                })
            <<< DateRow() { row in
                row.value = self.caseSheet.date
                row.title = "Date"
                }.onChange({ dateRow in
                    guard let date = dateRow.value else {return}
                    self.caseSheet.date = date
                })
            <<< LabelRow() { row in
                row.title = "Present Illness History"
            }
            <<< TextAreaRow { row in
                row.placeholder = "Enter history of present illness"
                row.value = self.caseSheet.illnessHistory
                }.onChange({ textrow in
                    guard let history = textrow.value else {return}
                    self.caseSheet.illnessHistory = history
                })
            <<< LabelRow() { row in
                row.title = "Medical History"
            }
            <<< TextAreaRow { row in
                row.placeholder = "Enter relevant medical history"
                row.value = self.caseSheet.medicalHistory
                }.onChange({ textrow in
                    guard let history = textrow.value else {return}
                    self.caseSheet.medicalHistory = history
                })
            <<< LabelRow() { row in
                row.title = "Family History"
            }
            <<< TextAreaRow { row in
                row.placeholder = "Enter family history"
                if self.caseSheet.familyHistory != "" {
                    row.value = self.caseSheet.familyHistory
                }
                }.onChange({ textrow in
                    guard let history = textrow.value else {return}
                    self.caseSheet.familyHistory = history
                })
            <<< LabelRow() { row in
                row.title = "Past dental History"
            }
            <<< TextAreaRow { row in
                row.placeholder = "Enter dental history"
                row.value = self.caseSheet.dentalHistory
                }.onChange({ textrow in
                    guard let history = textrow.value else {return}
                    self.caseSheet.dentalHistory = history
                })
            
            // MARK: - General Examination
            +++ Section("General Examination")
            <<< TextRow() { row in
                row.title = "Build and gait"
                row.placeholder = "description"
                row.value = self.caseSheet.generalExamination.gait
                }.onChange({ textrow in
                    guard let gait = textrow.value else {return}
                    self.caseSheet.generalExamination.gait = gait
                })
            <<< TextRow() { row in
                row.title = "Vital signs"
                row.placeholder = "description"
                row.value = self.caseSheet.generalExamination.vitals
                }.onChange({ textrow in
                    guard let vitals = textrow.value else {return}
                    self.caseSheet.generalExamination.vitals = vitals
                })
            <<< TextRow() { row in
                row.title = "Other findings"
                row.placeholder = "description"
                row.value = self.caseSheet.generalExamination.findings
                }.onChange({ textrow in
                    guard let findings = textrow.value else {return}
                    self.caseSheet.generalExamination.findings = findings
                })
            
            // MARK: - Extraoral Examination
            +++ Section("Extraoral Examination")
            <<< TextRow() { row in
                row.title = "Eyes, ears and nose"
                row.placeholder = "description"
                row.value = self.caseSheet.extraoralExamination.ent
                }.onChange({ textrow in
                    guard let ent = textrow.value else {return}
                    self.caseSheet.extraoralExamination.ent = ent
                })
            <<< TextRow() { row in
                row.title = "Facial symmetry"
                row.placeholder = "description"
                row.value = self.caseSheet.extraoralExamination.facialSymmetry
                }.onChange({ textrow in
                    guard let symmetry = textrow.value else {return}
                    self.caseSheet.extraoralExamination.facialSymmetry = symmetry
                })
            <<< TextRow() { row in
                row.title = "Facial profile"
                row.placeholder = "description"
                row.value = self.caseSheet.extraoralExamination.facialProfile
                }.onChange({ textrow in
                    guard let profile = textrow.value else {return}
                    self.caseSheet.extraoralExamination.facialProfile = profile
                })
            <<< TextRow() { row in
                row.title = "Lips"
                row.placeholder = "description"
                row.value = self.caseSheet.extraoralExamination.lips
                }.onChange({ textrow in
                    guard let lips = textrow.value else {return}
                    self.caseSheet.extraoralExamination.lips = lips
                })
            <<< TextRow() { row in
                row.title = "TMJ Examination"
                row.placeholder = "description"
                row.value = self.caseSheet.extraoralExamination.tmj
                }.onChange({ textrow in
                    guard let tmj = textrow.value else {return}
                    self.caseSheet.extraoralExamination.tmj = tmj
                })
            <<< TextRow() { row in
                row.title = "Lymph nodes"
                row.placeholder = "description"
                row.value = self.caseSheet.extraoralExamination.lymph
                }.onChange({ textrow in
                    guard let lymph = textrow.value else {return}
                    self.caseSheet.extraoralExamination.lymph = lymph
                })
            <<< TextRow() { row in
                row.title = "Mouth opening"
                row.placeholder = "description"
                row.value = self.caseSheet.extraoralExamination.mouth
                }.onChange({ textrow in
                    guard let mouth = textrow.value else {return}
                    self.caseSheet.extraoralExamination.mouth = mouth
                })
            
            // MARK: - Intraoral Examination
            +++ Section("Intraoral examination")
            +++ Section("Soft tissue examination")
            <<< TextRow() { row in
                row.title = "Labial Mucosa"
                row.placeholder = "description"
                row.value = self.caseSheet.intraoralExamination.softTissue.labialMucosa
                }.onChange({ textrow in
                    guard let labial = textrow.value else {return}
                    self.caseSheet.intraoralExamination.softTissue.labialMucosa = labial
                })
            <<< TextRow() { row in
                row.title = "Buccal Mucosa"
                row.placeholder = "description"
                row.value = self.caseSheet.intraoralExamination.softTissue.buccalMucosa
                }.onChange({ textrow in
                    guard let buccal = textrow.value else {return}
                    self.caseSheet.intraoralExamination.softTissue.buccalMucosa = buccal
                })
            <<< TextRow() { row in
                row.title = "Palate"
                row.placeholder = "description"
                row.value = self.caseSheet.intraoralExamination.softTissue.palate
                }.onChange({ textrow in
                    guard let palate = textrow.value else {return}
                    self.caseSheet.intraoralExamination.softTissue.palate = palate
                })
            <<< TextRow() { row in
                row.title = "Floor of mouth"
                row.placeholder = "description"
                row.value = self.caseSheet.intraoralExamination.softTissue.floorOfMouth
                }.onChange({ textrow in
                    guard let floor = textrow.value else {return}
                    self.caseSheet.intraoralExamination.softTissue.floorOfMouth = floor
                })
            <<< TextRow() { row in
                row.title = "Toungue"
                row.placeholder = "description"
                row.value = self.caseSheet.intraoralExamination.softTissue.tongue
                }.onChange({ textrow in
                    guard let tongue = textrow.value else {return}
                    self.caseSheet.intraoralExamination.softTissue.tongue = tongue
                })
            <<< TextRow() { row in
                row.title = "Vestibules"
                row.placeholder = "description"
                row.value = self.caseSheet.intraoralExamination.softTissue.vestibules
                }.onChange({ textrow in
                    guard let vestibules = textrow.value else {return}
                    self.caseSheet.intraoralExamination.softTissue.vestibules = vestibules
                })
            <<< TextRow() { row in
                row.title = "Faucial Pillars"
                row.placeholder = "description"
                row.value = self.caseSheet.intraoralExamination.softTissue.faucialPillers
                }.onChange({ textrow in
                    guard let pillars = textrow.value else {return}
                    self.caseSheet.intraoralExamination.softTissue.faucialPillers = pillars
                })
            +++ Section("Gingiva")
            <<< SuggestionTableRow<String> (){ row in
                row.filterFunction = { text in
                    let options = ["Pink", "Red", "White", "Blue", "hyperpigmented"]
                    return options.filter({ $0.lowercased().contains(text.lowercased())})
                }
                row.title = "Color"
                row.placeholder = "description"
                row.value = self.caseSheet.intraoralExamination.softTissue.gingiva.color
                }.onChange({ textrow in
                    guard let color = textrow.value else {return}
                    self.caseSheet.intraoralExamination.softTissue.gingiva.color = color
                })
            <<< SuggestionTableRow<String> () { row in
                row.filterFunction = { text in
                    let options = ["Smooth", "scalloped"]
                    return options.filter({ $0.lowercased().contains(text.lowercased())})
                }
                row.value = self.caseSheet.intraoralExamination.softTissue.gingiva.contour
                row.placeholder = "description"
                row.title = "Contour"
                }.onChange({ textrow in
                    guard let contour = textrow.value else {return}
                    self.caseSheet.intraoralExamination.softTissue.gingiva.contour = contour
                })
            <<< TextRow() { row in
                row.title = "Position"
                row.placeholder = "description"
                row.value = self.caseSheet.intraoralExamination.softTissue.gingiva.position
                }.onChange({ textrow in
                    guard let pos = textrow.value else {return}
                    self.caseSheet.intraoralExamination.softTissue.gingiva.position = pos
                })
            <<< TextRow() { row in
                row.title = "Surface Texture"
                row.placeholder = "description"
                row.value = self.caseSheet.intraoralExamination.softTissue.gingiva.surfaceTexture
                }.onChange({ textrow in
                    guard let texture = textrow.value else {return}
                    self.caseSheet.intraoralExamination.softTissue.gingiva.surfaceTexture = texture
                })
            <<< TextRow() { row in
                row.title = "Consistency"
                row.placeholder = "description"
                row.value = self.caseSheet.intraoralExamination.softTissue.gingiva.consistency
                }.onChange({ textrow in
                    guard let consistency = textrow.value else {return}
                    self.caseSheet.intraoralExamination.softTissue.gingiva.consistency = consistency
                })
            <<< TextRow() { row in
                row.title = "Periodontal Pockets"
                row.placeholder = "description"
                row.value = self.caseSheet.intraoralExamination.softTissue.gingiva.periodontalPockets
                }.onChange({ textrow in
                    guard let pockets = textrow.value else {return}
                    self.caseSheet.intraoralExamination.softTissue.gingiva.periodontalPockets = pockets
                })
            +++ Section("")
            <<< TextRow() { row in
                row.title = "Oral hygiene status"
                row.placeholder = "hygiene status"
                row.value = self.caseSheet.intraoralExamination.hygieneStatus
                }.onChange({ textrow in
                    guard let hygiene = textrow.value else {return}
                    self.caseSheet.intraoralExamination.hygieneStatus = hygiene
                })
            <<< SegmentedRow<String>() { row in
                row.title = "Halitosis"
                row.options = ["Yes","No"]
                if self.caseSheet.intraoralExamination.halitosis {
                    row.value = "Yes"
                }
                else { row.value = "No" }
                }.cellSetup { cell, _ in
                    guard let titleLabel = cell.titleLabel else {return}
                    cell.segmentedControl.widthAnchor.constraint(equalTo: titleLabel.widthAnchor).isActive = true
                }.onChange({ segmentedRow in
                    guard let halitosis = segmentedRow.value else {return}
                    switch(halitosis){
                    case "Yes":
                        self.caseSheet.intraoralExamination.halitosis = true
                    default:
                        self.caseSheet.intraoralExamination.halitosis = false
                    }
                })
            <<< SegmentedRow<String>() { row in
                row.title = "Stains"
                row.options = ["Yes","No"]
                if self.caseSheet.intraoralExamination.stains {
                    row.value = "Yes"
                }
                else { row.value = "No" }
                }.cellSetup { cell, _ in
                    guard let titleLabel = cell.titleLabel else {return}
                    cell.segmentedControl.widthAnchor.constraint(equalTo: titleLabel.widthAnchor).isActive = true
                }.onChange({ segmentedRow in
                    guard let stains = segmentedRow.value else {return}
                    switch(stains){
                    case "Yes":
                        self.caseSheet.intraoralExamination.stains = true
                    default:
                        self.caseSheet.intraoralExamination.stains = false
                    }
                })
            <<< SegmentedRow<String>() { row in
                row.title = "Calculus"
                row.options = ["Yes","No"]
                if self.caseSheet.intraoralExamination.calculus {
                    row.value = "Yes"
                }
                else { row.value = "No" }
                }.cellSetup { cell, _ in
                    guard let titleLabel = cell.titleLabel else {return}
                    cell.segmentedControl.widthAnchor.constraint(equalTo: titleLabel.widthAnchor).isActive = true
                }.onChange({ segmentedRow in
                    guard let calculus = segmentedRow.value else {return}
                    switch(calculus){
                    case "Yes":
                        self.caseSheet.intraoralExamination.calculus = true
                    default:
                        self.caseSheet.intraoralExamination.calculus = false
                    }
                })
        // MARK: - Teeth status view
        teethViewRow = TeethViewRow() { row in
            row.cell.cellPressed = { button in
                if let idx = self.teethStatuses.firstIndex(of: self.teethStatus) {
                    button.setTitle(self.teethStatusesShort[idx], for: .normal)
                }
                else {
                    button.setTitle("-", for: .normal)
                }
            }
            if self.caseSheet.intraoralExamination.hardTissue.count > 0{
                print("Teeth view load")
                print(self.caseSheet.intraoralExamination.hardTissue.count)
                for i in Range(1...self.caseSheet.intraoralExamination.hardTissue.count-1) {
                    row.cell.statusButtons[i].titleLabel?.text = self.caseSheet.intraoralExamination.hardTissue[i]
                }
            }
        }
        // MARK: - Hard tissue examination
        form +++ Section("Hard tissue examination")
            <<< PushRow<String>(){ row in
                row.title = "Mark cells as"
                row.options = self.teethStatuses
                }.onChange({ pushrow in
                    if let selection = pushrow.value {
                        self.teethStatus = selection
                    }
                    else {
                        self.teethStatus = ""
                    }
                })
            <<< teethViewRow
            +++ Section("Description of specific findings")
            <<< TextAreaRow() { row in
                row.placeholder = "Description"
                row.value = self.caseSheet.specificFindings
                }.onChange({ textAreaRow in
                    if let txt = textAreaRow.value {
                        self.caseSheet.specificFindings = txt
                    }
                    else {
                        self.caseSheet.specificFindings = ""
                    }
                })
            +++ Section("Clinical Diagnosis")
            <<< TextAreaRow() { row in
                row.placeholder = "Description"
                row.value = self.caseSheet.clinicalDiagnosis
                }.onChange({ textAreaRow in
                    if let txt = textAreaRow.value {
                        self.caseSheet.clinicalDiagnosis = txt
                    }
                    else {
                        self.caseSheet.clinicalDiagnosis = ""
                    }
                })
            +++ Section("Differential Diagnosis")
            <<< TextAreaRow() { row in
                row.placeholder = "Description"
                row.value = self.caseSheet.differentialDiagnosis
                }.onChange({ textAreaRow in
                    if let txt = textAreaRow.value {
                        self.caseSheet.differentialDiagnosis = txt
                    }
                    else {
                        self.caseSheet.differentialDiagnosis = ""
                    }
                })
            +++ Section("Investigation and results")
            <<< TextAreaRow() { row in
                row.placeholder = "Description"
                row.value = self.caseSheet.investigationsAndResults
                }.onChange({ textAreaRow in
                    if let txt = textAreaRow.value {
                        self.caseSheet.investigationsAndResults = txt
                    }
                    else {
                        self.caseSheet.investigationsAndResults = ""
                    }
                })
            +++ Section("Final diagnosis")
            <<< TextAreaRow() { row in
                row.placeholder = "Description"
                row.value = self.caseSheet.finalDiagnosis
                }.onChange({ textAreaRow in
                    if let txt = textAreaRow.value {
                        self.caseSheet.finalDiagnosis = txt
                    }
                    else {
                        self.caseSheet.finalDiagnosis = ""
                    }
                })
        treatmentsSection = MultivaluedSection(multivaluedOptions: [.Reorder, .Insert, .Delete],
                                               header: "Treatment Plan", footer: "List out steps in treatment plan"){ section in
                                                section.addButtonProvider = { sec in
                                                    return ButtonRow(){ row in
                                                        row.title = "Add treatment step"
                                                    }
                                                }
                                                section.multivaluedRowToInsertAt = { index in
                                                    return TextRow() { row in
                                                        row.placeholder = "Treatment step"
                                                    }
                                                }
                                                if let treatments = self.caseSheet.treatmentPlan {
                                                    for plan in treatments {
                                                        section <<< TextRow { row in
                                                            row.value = plan
                                                        }
                                                    }
                                                }
                                                else{
                                                    section <<< TextRow { row in
                                                        row.placeholder = "Treatment step"
                                                    }
                                                }
        }
        drugsSection = MultivaluedSection(multivaluedOptions: [.Reorder, .Insert, .Delete],
                                          header: "Drugs prescribed", footer: "List prescribed drugs"){ section in
                                            section.addButtonProvider = { sec in
                                                return ButtonRow(){ row in
                                                    row.title = "Add drug step"
                                                }
                                            }
                                            section.multivaluedRowToInsertAt = { index in
                                                return TextRow() { row in
                                                    row.placeholder = "Drug name"
                                                }
                                            }
                                            if let drugs = self.caseSheet.prescriptions {
                                                for drug in drugs {
                                                    section <<< TextRow { row in
                                                        row.value = drug
                                                    }
                                                }
                                            }
                                            else{
                                                section <<< TextRow { row in
                                                    row.placeholder = "Drug name"
                                                }
                                            }
        }

        deptVisitPriority = MultivaluedSection(multivaluedOptions: [.Reorder, .Insert, .Delete],
                                               header: "Priority", footer: "priority in which to visit other departments"){ section in
                                                section.addButtonProvider = { sec in
                                                    return ButtonRow(){ row in
                                                        row.title = "Add department"
                                                    }
                                                }
                                                section.multivaluedRowToInsertAt = { index in
                                                    return PushRow<String>() { row in
                                                        row.options = self.deptList
                                                    }
                                                }
                                                if let visitPriority = self.caseSheet.visitPriority {
                                                    for dept in visitPriority{
                                                        section <<< PushRow<String>(){ row in
                                                            row.options = self.deptList
                                                            row.value = dept
                                                        }
                                                    }
                                                }
        }
        form +++ treatmentsSection
            +++ drugsSection
            +++ deptVisitPriority
            +++ Section("Examined by")
            <<< TextRow() { row in
                row.title = "Student"
                row.placeholder = "Student name"
            }
            <<< TextRow() { row in
                row.title = "Staff"
                row.placeholder = "Staff name"
                if let username = self.defaults.string(forKey: "username") {
                    row.value = username
                }
            }
            <<< ButtonRow() { row in
                row.title = "Submit"
                }.onCellSelection({ buttonCell, buttonRow in
                    self.updateListItems()
                    let error = self.form.validate()
                    if error.count > 0 {
                        print(error)
                        let alert = UIAlertController(title: "Error", message: "Please fill all required fields", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { _ in
                            return
                        }))
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    let alert = UIAlertController(title: "Submit?", message: "This action cannot be undone", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: { _ in
                        return
                    }))
                    alert.addAction(UIAlertAction(title: "Submit",style: UIAlertAction.Style.default,handler: {(_: UIAlertAction!) in
                        
                        
                            do{
                                //Patient
                                let data = try FirebaseEncoder().encode(self.patient)

                                 self.ref?.child("Patients").child(self.patient.id).setValue(data)
                                                        
                                 //CaseSheet
                                 let data2 = try FirebaseEncoder().encode(self.caseSheet)
                                self.ref?.child(self.patient.id).child("CaseSheet").setValue(data2)
                                
                                print(data2)
                                
                                
                                //refering

                                var refer = [String:String]()
                                refer.updateValue(self.patient.name, forKey: "Name")
                                refer.updateValue(self.patient.phone, forKey: "Phone")
                                let df = DateFormatter()
                                df.dateFormat = "dd-MM-yyyy"
                                let now = df.string(from: self.caseSheet.date)
                                refer.updateValue(now, forKey: "date")
                                guard let visitPriority = self.caseSheet.visitPriority else {return}
                                let dept = visitPriority[0]
                                var department:String = ""
                                
                                if dept == "2. Conservative Dentistry"{
                                    department = "department1"
                                }
                                if dept == "3. Periodontics"{
                                    department = "department2"
                                }
                                if dept == "4. Oral & Maxillofacial Surgery"{
                                    department = "department3"
                                }
                                if dept == "5. Prosthodontics"{
                                    department = "department4"
                                }
                                if dept == "6. Pedodontics"{
                                    department = "department5"
                                }
                                if dept ==  "7. Orthodontics"{
                                    department = "department6"
                                }
                                
                                
                                self.ref?.child("dept_list").child(department).child(self.patient.id).updateChildValues(refer)
                                
                                self.navigationController?.popViewController(animated: true)
                                
                            }
                            catch {
                                    print("error")
                            }
                    }))
                    self.present(alert, animated: true, completion: nil)
                    
                })
    }
    func updateListItems(){
        self.caseSheet.treatmentPlan = treatmentsSection.values() as? [String] ?? []
        self.caseSheet.prescriptions = drugsSection.values() as? [String] ?? []
        self.caseSheet.visitPriority = deptVisitPriority.values() as? [String] ?? []
        self.caseSheet.intraoralExamination.hardTissue = []
        guard let statusButtons = teethViewRow.cell.statusButtons else {return}
        for statusButton in statusButtons {
            if let titleLabel = statusButton.titleLabel { self.caseSheet.intraoralExamination.hardTissue.append(titleLabel.text ?? "-")
            }
            else { print("No title lable while loading")}
        }
        print(self.caseSheet)
    }
    
    @objc func editButtonPushed(_ sender: UIButton){
        print("Toggled edit")
        self.allowEdits = !self.allowEdits
        print(self.allowEdits)
        updateEditMode()
    }
    
    func updateEditMode(){
        for row in form.allRows{
            row.baseCell.isUserInteractionEnabled = self.allowEdits
        }
    }
}
