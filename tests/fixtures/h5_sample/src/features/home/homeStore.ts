import { create } from "zustand";

type HomeState = {
  title: string;
  setTitle: (title: string) => void;
};

export const useHomeStore = create<HomeState>((set) => ({
  title: "Home",
  setTitle: (title) => set({ title }),
}));
