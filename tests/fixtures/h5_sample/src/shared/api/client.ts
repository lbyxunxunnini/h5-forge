import axios from "axios";

const client = axios.create({ baseURL: "/api" });

export async function fetchHome(): Promise<{ title: string }> {
  const response = await client.get("/home");
  return response.data;
}
