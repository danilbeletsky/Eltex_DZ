import SwiftUI

struct HeatmapCell: View {
    let title: String
    let color: Color
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(12)
            .background(color)
    }
}

struct HeatmapScreen: View {
    var body: some View {
        VStack(spacing: 4){
            HeatmapCell(title: "RUB", color: .red)
            HStack{
                VStack{
                    HeatmapCell(title: "USD", color: .blue)
                    HStack{
                        HeatmapCell(title: "XCD", color: .yellow)
                        HeatmapCell(title: "BHD", color: .orange)
                    }
                }
                VStack{
                    HStack{
                        VStack{
                            HeatmapCell(title: "ALL", color: .cyan)
                            HeatmapCell(title: "BZD", color: .mint)
                        }
                        VStack{
                            HeatmapCell(title: "AFN", color: .brown)
                            HeatmapCell(title: "BYN", color: .red)
                        }
                    }
                    VStack{
                        HStack{
                            HeatmapCell(title: "XCD", color: .gray)
                            HeatmapCell(title: "BDT", color: .indigo)
                        }
                        HStack{
                            VStack{
                                HeatmapCell(title: "BSD", color: .pink)
                                HeatmapCell(title: "XOF", color: .yellow)
                            }
                            VStack{
                                HeatmapCell(title: "BBD", color: .green)
                                HeatmapCell(title: "BOB", color: .blue)
                            }
                        }
                    }
                }
            }
        }
        .padding(.init(top: 2, leading: 2, bottom: 2, trailing: 2))
    }
}
