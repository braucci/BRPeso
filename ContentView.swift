//
//  ContentView.swift
//  BRpeso
//
//  Created by Biagio Raucci on 28/08/2023.
//

import SwiftUI
import LocalAuthentication

struct WeightEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var weight: Double
}

struct ContentView: View {
    @State private var data: [WeightEntry] = []
    @State private var currentDate = Date()
    @State private var currentWeight: String = ""
    @State private var weightDifference: Double = 0.0
    @State private var showingForm = false
    @State private var authenticated = false
    
    var body: some View {
        Group {
            if authenticated {
                NavigationView {
                    List {
                        ForEach(data.sorted(by: { $0.date < $1.date })) { entry in
                            NavigationLink(
                                destination: EditView(entry: entry, updateAction: updateEntry)
                            ) {
                                HStack {
                                    Text("\(entry.date, formatter: dateFormatter)")
                                    Spacer()
                                    Text("\(entry.weight, specifier: "%.2f") kg")
                                }
                            }
                        }
                        .onDelete(perform: deleteItem)
                    }
                    .navigationBarTitle("Registro del Peso", displayMode: .inline)
                    .navigationBarItems(
                        leading: EditButton(),
                        trailing:
                            Button(action: {
                                self.showingForm = true
                            }) {
                                Image(systemName: "plus")
                            }
                    )
                    .toolbar {
                        ToolbarItem(placement: .bottomBar) {
                            Text("Differenza di peso: \(weightDifference, specifier: "%.2f") kg")
                        }
                    }
                    .sheet(isPresented: $showingForm) {
                        VStack {
                            Form {
                                DatePicker("Data", selection: $currentDate, displayedComponents: .date)
                                TextField("Peso (kg)", text: $currentWeight)
                                    .keyboardType(.decimalPad)
                            }
                            
                            Button("Aggiungi") {
                                if let weight = Double(currentWeight) {
                                    self.data.append(WeightEntry(date: currentDate, weight: weight))
                                    self.saveData()
                                    self.calculateWeightDifference()
                                    self.showingForm = false
                                }
                            }
                            .disabled(currentWeight.isEmpty)
                        }
                    }
                    .onAppear(perform: loadData)
                }
            } else {
                Text("Non autenticato")
            }
        }
        .onAppear(perform: authenticate)
    }
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()
    
    private func deleteItem(at offsets: IndexSet) {
        data.remove(atOffsets: offsets)
        saveData()
        calculateWeightDifference()
    }
    
    private func updateEntry(with updatedEntry: WeightEntry) {
        if let index = data.firstIndex(where: { $0.id == updatedEntry.id }) {
            data[index] = updatedEntry
            saveData()
            calculateWeightDifference()
        }
    }
    
    func loadData() {
        if let savedData = UserDefaults.standard.value(forKey: "WeightData") as? Data,
           let decodedData = try? JSONDecoder().decode([WeightEntry].self, from: savedData) {
            data = decodedData
            calculateWeightDifference()
        }
    }
    
    func saveData() {
        if let encodedData = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encodedData, forKey: "WeightData")
        }
    }
    
    func calculateWeightDifference() {
        if let firstWeight = data.sorted(by: { $0.date < $1.date }).first?.weight,
           let lastWeight = data.sorted(by: { $0.date < $1.date }).last?.weight {
            weightDifference = lastWeight - firstWeight
        }
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Identificati per accedere ai tuoi dati."
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.authenticated = true
                        self.loadData()
                    } else {
                        // Gestire il fallimento dell'autenticazione
                        print("Autenticazione fallita: \(String(describing: authenticationError))")
                        self.authenticated = false
                    }
                }
            }
        } else {
            // Nessuna autenticazione biometrica disponibile
            print("Nessuna autenticazione biometrica disponibile")
            self.authenticated = false
        }
    }
}

struct EditView: View {
    var entry: WeightEntry
    var updateAction: (WeightEntry) -> Void
    @State private var selectedDate: Date
    @State private var weightString: String
    @Environment(\.presentationMode) var presentationMode
    
    init(entry: WeightEntry, updateAction: @escaping (WeightEntry) -> Void) {
        self.entry = entry
        self.updateAction = updateAction
        _selectedDate = State(initialValue: entry.date)
        _weightString = State(initialValue: "\(entry.weight)")
    }
    
    var body: some View {
        Form {
            DatePicker("Data", selection: $selectedDate, displayedComponents: .date)
            TextField("Peso (kg)", text: $weightString)
                .keyboardType(.decimalPad)
        }
        .navigationBarTitle("Modifica Entry", displayMode: .inline)
        .navigationBarItems(trailing: Button("Salva") {
            if let weight = Double(weightString) {
                let updatedEntry = WeightEntry(id: entry.id, date: selectedDate, weight: weight)
                updateAction(updatedEntry)
                presentationMode.wrappedValue.dismiss()
            }
        })
    }
}
