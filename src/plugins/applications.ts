import { invoke } from "@tauri-apps/api/tauri";
import { IItemGroup } from "../components/ItemGroup.vue";

export default class ApplicationsPlugin {
  public isLoading = true;
  public itemGroup: IItemGroup | null = null;

  public getItemGroup(): IItemGroup | null {
    return this.itemGroup;
  }

  public async initialize() {
    await this.loadData();
  }

  public async loadData() {
    this.itemGroup = await invoke("get_applications_group");
    this.isLoading = false;
  }
}