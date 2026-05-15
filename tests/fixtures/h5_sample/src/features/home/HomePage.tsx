import { useEffect } from "react";
import { fetchHome } from "../../shared/api/client";
import { useHomeStore } from "./homeStore";

export function HomePage() {
  const setTitle = useHomeStore((state) => state.setTitle);
  const title = useHomeStore((state) => state.title);

  useEffect(() => {
    fetchHome().then((data) => setTitle(data.title));
  }, [setTitle]);

  return <main>{title}</main>;
}
