//
//  EnterInputView.swift
//  BPTracker
//
//  Created by Mark A Stewart on 4/5/24.
//

import SwiftUI
import SwiftData

enum MMHgBase: Int {
    case systolicBase = 90
    case distolicBase = 60
}

enum MMHgLimit: Int {
    case systolicLimit = 166
    case distolicLimit = 121
}

struct EnterInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var showEnterBPInput: Bool
    @State var bpTimeStamp = Date()

        // Optional Int state so a focused field can be blanked out instead of showing a default number user has to manually delete.
    @State var systolicInput: Int? = MMHgBase.systolicBase.rawValue + 20
    @State var distolicInput: Int? = MMHgBase.distolicBase.rawValue + 10
    @State var pulseInput: Int? = 72

    private enum Field: Hashable {
        case systolic, distolic, pulse
    }
    @FocusState private var focusedField: Field?

    private var systolicRange: ClosedRange<Int> {
        MMHgBase.systolicBase.rawValue...(MMHgLimit.systolicLimit.rawValue - 1)
    }
    private var distolicRange: ClosedRange<Int> {
        MMHgBase.distolicBase.rawValue...(MMHgLimit.distolicLimit.rawValue - 1)
    }
    private let pulseRange = 25...300

    private var isSystolicValid: Bool {
        guard let systolicInput else { return false }
        return systolicRange.contains(systolicInput)
    }
    private var isDistolicValid: Bool {
        guard let distolicInput else { return false }
        return distolicRange.contains(distolicInput)
    }
    private var isPulseValid: Bool {
        guard let pulseInput else { return false }
        return pulseRange.contains(pulseInput)
    }
    private var canSave: Bool { isSystolicValid && isDistolicValid && isPulseValid }

    var body: some View {
        HStack {
            Spacer()
            Text("Blood Pressure Input").font(.headline).padding(.vertical, 35)
            Spacer()
        }

        VStack {
            HStack {
                DatePicker("Date of Reading", selection: $bpTimeStamp, displayedComponents: .date)
                Spacer()
            }.padding(.horizontal, 20)

            HStack {
                DatePicker("Time of Reading", selection: $bpTimeStamp, displayedComponents: .hourAndMinute)
                Spacer()
            }.padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Systolic:")
                    TextField("Systolic", value: $systolicInput, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.center)
                        .foregroundColor(isSystolicValid ? .primary : .red)
                        .focused($focusedField, equals: .systolic)
                    Spacer()
                }
                if !isSystolicValid {
                    Text("Enter a value between \(systolicRange.lowerBound) and \(systolicRange.upperBound)")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }.padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Diastolic:")
                    TextField("Diastolic", value: $distolicInput, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.center)
                        .foregroundColor(isDistolicValid ? .primary : .red)
                        .focused($focusedField, equals: .distolic)
                    Spacer()
                }
                if !isDistolicValid {
                    Text("Enter a value between \(distolicRange.lowerBound) and \(distolicRange.upperBound)")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }.padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Pulse:")
                    TextField("Pulse", value: $pulseInput, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.center)
                        .foregroundColor(isPulseValid ? .primary : .red)
                        .focused($focusedField, equals: .pulse)
                    Spacer()
                }
                if !isPulseValid {
                    Text("Enter a value between \(pulseRange.lowerBound) and \(pulseRange.upperBound)")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }.padding(.horizontal, 20)

            HStack {
                Button("Save") {
                    guard let systolic = systolicInput,
                          let diastolic = distolicInput,
                          let pulse = pulseInput else { return }
                    BPDetails().saveBPDetails(context: modelContext, bpTimeStamp: bpTimeStamp, systolic: systolic, diastolic: diastolic, pulse: pulse)
                    showEnterBPInput = false
                }
                .disabled(!canSave)
                Spacer()
                Button("Cancel") {
                    showEnterBPInput = false
                }
            }.padding(.horizontal, 50).padding(.vertical, 20)
        }
        .font(.subheadline)
        .onChange(of: focusedField) { _, newValue in
                // Clear the field just gained focus so user types straight into an empty box instead of deleting old value.
            switch newValue {
            case .systolic: systolicInput = nil
            case .distolic: distolicInput = nil
            case .pulse: pulseInput = nil
            case nil: break
            }
        }
    }
}
