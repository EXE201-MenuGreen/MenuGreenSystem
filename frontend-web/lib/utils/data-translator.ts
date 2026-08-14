const dictionary: Record<string, string> = {
  // Meal Types
  breakfast: "Bữa sáng",
  lunch: "Bữa trưa",
  dinner: "Bữa tối",
  snack: "Bữa phụ",
  // Statuses
  pending: "Chờ duyệt",
  accepted: "Đã duyệt",
  approved: "Đã duyệt",
  rejected: "Từ chối",
  completed: "Hoàn thành",
  // Categories
  meat: "Thịt",
  vegetables: "Rau củ",
  vegetable: "Rau củ",
  fruits: "Trái cây",
  fruit: "Trái cây",
  dairy: "Sữa",
  seafood: "Hải sản",
  carb: "Tinh bột",
  carbs: "Tinh bột",
  fat: "Chất béo",
  fats: "Chất béo",
  protein: "Đạm",
  proteins: "Đạm",
  spice: "Gia vị",
  spices: "Gia vị",
  drink: "Đồ uống",
  drinks: "Đồ uống",
  salad: "Salad",
  soup: "Canh/Súp",
  dessert: "Tráng miệng",
  main: "Món chính",
  side: "Món phụ",
  appetizer: "Khai vị",
};

export function translateData(data?: string | null): string {
  if (!data) return "";
  const key = data.trim().toLowerCase();
  return dictionary[key] ?? data;
}
