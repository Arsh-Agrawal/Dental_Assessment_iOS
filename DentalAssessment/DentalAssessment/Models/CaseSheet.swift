//
//  CaseSheet.swift
//  DentalAssessment
//
//  Created by student on 08/10/19.
//  Copyright © 2019 student. All rights reserved.
//

import Foundation

struct CaseSheet{
    var id: String = ""
    var patient: Patient = Patient()
    var hospitalNum: Int = 0
    var date: Date = Date()
    var illnessHistory: String = ""
    var medicalHistory: String = ""
    var familyHistory: String = ""
    var dentalHistory: String = ""
    var personalHistory: PersonalHistory = PersonalHistory()
    var generalExamination: GeneralExamination = GeneralExamination()
    var extraoralExamination: ExtraoralExamination = ExtraoralExamination()
    var intraoralExamination: IntraoralExamination = IntraoralExamination()
    var clinicalDiagnosis: String = ""
    var differentialDiagnosis: String = ""
    var investigationsAndResults: String = ""
    var finalDiagnosis: String = ""
    var treatmentPlan: [String] = []
    var prescriptions: [String] = []
    var studentExaminer: Student?
    var staffExaminer: Staff?
}
